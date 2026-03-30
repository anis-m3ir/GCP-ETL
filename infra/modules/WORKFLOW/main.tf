# =============================================================================
# WORKFLOW MODULE - Orchestration & Execution
# =============================================================================
# Business Domain: Data WORKFLOW orchestration and execution
# 
# This module manages all resources for orchestrating and executing the ELT
# pipeline including workflows, event triggers, and serverless compute.
# =============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# =============================================================================
# GCP APIs - Enable Pipeline-Specific Services
# =============================================================================

resource "google_project_service" "workflows_api" {
  project                    = var.project_id
  service                    = "workflows.googleapis.com"
  disable_dependent_services = true
  disable_on_destroy         = false
}

resource "google_project_service" "cloud_run_api" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "eventarc_api" {
  project            = var.project_id
  service            = "eventarc.googleapis.com"
  disable_on_destroy = false
}

# -----------------------------------------------------------------------------
# API Propagation Delay
# -----------------------------------------------------------------------------
# Wait for Pipeline APIs to propagate before creating dependent resources

resource "time_sleep" "wait_for_pipeline_apis" {
  create_duration = "90s"

  depends_on = [
    google_project_service.workflows_api,
    google_project_service.cloud_run_api,
    google_project_service.eventarc_api
  ]
}

# =============================================================================
# CLOUD RUN JOB - dbt Execution Environment
# =============================================================================

resource "google_cloud_run_v2_job" "dbt_runner" {
  name     = var.dbt_job_name
  location = var.region

  template {
    template {
      # Job runs AS retail-etl-sa (for Cloud Run orchestration)
      service_account = var.retail_etl_sa_email
      max_retries     = 1
      timeout         = "1800s" # 30 minutes max

      containers {
        image = var.dbt_image
        args  = ["run"] # dbt run command

        # Mount secret containing dbt-runner credentials
        volume_mounts {
          name       = "dbt-sa-secret"
          mount_path = "/secrets"
        }

        # Environment variables for dbt BigQuery connection
        env {
          name  = "GOOGLE_APPLICATION_CREDENTIALS"
          value = "/secrets/dbt-keyfile"
        }

        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "DBT_DATASET"
          value = var.dataset_id
        }

        # Resource limits
        resources {
          limits = {
            cpu    = "2"
            memory = "2Gi"
          }
        }
      }

      # Volume definition for secret (contains dbt-runner key)
      volumes {
        name = "dbt-sa-secret"
        secret {
          secret       = var.dbt_runner_secret_id
          default_mode = 0444 # Read-only
          items {
            version = "latest"
            path    = "dbt-keyfile"
          }
        }
      }
    }
  }

  depends_on = [
    google_project_service.cloud_run_api,
    time_sleep.wait_for_pipeline_apis
  ]
}
# =============================================================================
# IAM BINDINGS - Cloud Run Job Permissions
# =============================================================================

# Grant retail-etl-sa permission to invoke the dbt Cloud Run job
resource "google_cloud_run_v2_job_iam_member" "dbt_job_invoker" {
  name     = google_cloud_run_v2_job.dbt_runner.name
  location = google_cloud_run_v2_job.dbt_runner.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.retail_etl_sa_email}"
}

# =============================================================================
# LOAD VARS TO YAML
# =============================================================================

locals {
  # Template workflow YAML with runtime variables
  workflow_yaml = templatefile("${path.module}/workflow.yaml", {
    dataset_id    = var.dataset_id
    region        = var.region
    dbt_job_name  = var.dbt_job_name
    bucket_name   = var.bucket_name
    workflow_name = var.workflow_name
  })
}

# =============================================================================
# CLOUD WORKFLOWS - Orchestration Engine
# =============================================================================

resource "google_workflows_workflow" "etl_pipeline" {
  name            = var.workflow_name
  description     = "Retail ETL pipeline - Load raw CSV to BigQuery and execute dbt transformations"
  region          = var.region
  service_account = var.retail_etl_sa_email

  # Workflow definition (YAML)
  source_contents = local.workflow_yaml

  depends_on = [
    google_project_service.workflows_api,
    time_sleep.wait_for_pipeline_apis
  ]
}

# =============================================================================
# EVENTARC TRIGGER - Event-Driven Automation
# =============================================================================

resource "google_eventarc_trigger" "gcs_file_upload" {
  name            = "${var.workflow_name}-trigger"
  location        = "eu" # Eventarc uses multi-region for GCS events
  service_account = var.retail_etl_sa_email

  # Trigger on GCS object finalized (file upload complete)
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  # Filter to specific bucket
  matching_criteria {
    attribute = "bucket"
    value     = var.bucket_name
  }

  # Execute workflow when triggered
  destination {
    workflow = google_workflows_workflow.etl_pipeline.id
  }

  depends_on = [
    google_project_service.eventarc_api,
    time_sleep.wait_for_pipeline_apis
  ]
}


# =============================================================================
# CI/CD - CLOUD BUILD TRIGGER
# =============================================================================
# Conditional Cloud Build trigger for GitOps automation
# 
# IMPORTANT: Only created when var.create_cloud_build_trigger = true
# 
# PREREQUISITE: GitHub 2nd gen connection must be created first via console
# 1. Go to Cloud Build > Repositories (2nd gen)
# 2. Create connection: projects/{PROJECT_ID}/locations/europe-west9/connections/github-connection
# 3. Authorize GitHub OAuth
# 4. Link repository
# 5. Set create_cloud_build_trigger = true in terraform.tfvars
# 
# This trigger automatically:
# - Builds dbt Docker image (tagged with git SHA)
# - Runs terraform plan
# - Runs terraform apply with new image
# 
# Architecture:
# - cloudbuild-sa runs the build and terraform
# - retail-etl-sa runs workflows and cloud run jobs
# - dbt-runner executes dbt transformations

resource "google_cloudbuild_trigger" "main_branch_deploy" {
  name        = "retail-platform-deploy"
  description = "Deploy retail data platform on main branch push"
  location    = "europe-west1" # Must match GitHub connection region

  repository_event_config {
    repository = "projects/${var.project_id}/locations/europe-west1/connections/github-connection/repositories/${var.github_owner}-${var.github_repo_name}"

    push {
      branch = var.cloudbuild_trigger_branch
    }
  }

  filename = "cloudbuild.yaml"

  # Use cloudbuild-sa for infrastructure deployment
  service_account = var.cloudbuild_sa_id

  substitutions = {
    _TF_STATE_BUCKET      = var.tf_state_bucket
    _TF_STATE_PREFIX      = var.tf_state_prefix
    _AR_REGION            = var.region
    _AR_REPO              = var.ar_repo_name
    _WORKFLOW_NAME        = var.workflow_name
    _DATASET_ID           = var.dataset_id
    _BUCKET_NAME          = var.bucket_name
    _DBT_JOB_NAME         = var.dbt_job_name
  }

  depends_on = [time_sleep.wait_for_pipeline_apis]
}
