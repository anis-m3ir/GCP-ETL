# GCS Bucket - stockage des fichiers CSV
resource "google_storage_bucket" "bucket" {
  name                        = "retail-etl-dga"
  location                    = "EU"
  uniform_bucket_level_access = true
  force_destroy               = true
}

# BigQuery Dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id    = "retail_dga"
  friendly_name = "Retail Dataset"
  description   = "Retail Dataset"
  location      = "EU"
}

# terraform to create table in bigquery
resource "google_bigquery_table" "raw_country" {
  dataset_id = "retail_dga"
  table_id   = "raw_country"
  schema     = <<EOF
  [
    {"name": "id",        "type": "STRING"},
    {"name": "iso",       "type": "STRING"},
    {"name": "name",      "type": "STRING"},
    {"name": "nicename",  "type": "STRING"},
    {"name": "iso3",      "type": "STRING"},
    {"name": "numcode",   "type": "STRING"},
    {"name": "phonecode", "type": "STRING"}
  ]
  EOF
}

# terraform to create table raw_invoice
resource "google_bigquery_table" "raw_invoice" {
  dataset_id = "retail_dga"
  table_id   = "raw_invoice"
  schema     = <<EOF
  [
    {"name": "InvoiceNo",   "type": "STRING"},
    {"name": "StockCode",   "type": "STRING"},
    {"name": "Description", "type": "STRING"},
    {"name": "Quantity",    "type": "STRING"},
    {"name": "InvoiceDate", "type": "STRING"},
    {"name": "UnitPrice",   "type": "STRING"},
    {"name": "CustomerID",  "type": "STRING"},
    {"name": "Country",     "type": "STRING"}
  ]
  EOF
}

# WORKFLOW
resource "google_workflows_workflow" "workflow" {
  name            = "retail-dga-workflow"
  description     = "Retail Dataset Workflow"
  source_contents = local.workflow_yaml
  region          = var.region
  service_account = google_service_account.service_account.email
}

# terraform to enable IAM API
resource "google_project_service" "service" {
  service = "iam.googleapis.com"
}

# terraform to create service account
resource "google_service_account" "service_account" {
  account_id   = "retail-etl-sa"
  display_name = "Retail ETL SA"
}

# Self-impersonation pour Cloud Build trigger
resource "google_service_account_iam_member" "sa_self_impersonation" {
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.service_account.email}"
}

# terraform to enable Cloud Run API
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}

# terraform to enable Secret Manager API
resource "google_project_service" "secret_manager_api" {
  service = "secretmanager.googleapis.com"
}

# Grant BigQuery permissions to service account
resource "google_project_iam_member" "dbt_bigquery_user" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "dbt_bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# terraform to enable Artifact Registry API
resource "google_project_service" "artifact_registry_api" {
  service = "artifactregistry.googleapis.com"
}

# terraform to create Artifact Registry Docker repository for dbt images
resource "google_artifact_registry_repository" "dbt_images" {
  location      = var.region
  repository_id = var.ar_repo_name
  description   = "dbt images"
  format        = "DOCKER"
}

# terraform to grant roles gcs reader to service account
resource "google_project_iam_member" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# terraform to grant roles workflow invoker to service account
resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# terraform to grant roles eventarc admin to service account
resource "google_project_iam_member" "eventarc_admin" {
  project = var.project_id
  role    = "roles/eventarc.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "eventarc_storage_check" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Permission storage sur le bucket de state Terraform
resource "google_project_iam_member" "storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Permission logging pour Cloud Build
resource "google_project_iam_member" "logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Permission Cloud Build
resource "google_project_iam_member" "cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# terraform to create Cloud Run Job to execute dbt with BigQuery
resource "google_cloud_run_v2_job" "dbt" {
  name     = var.dbt_job_name
  location = var.region

  template {
    template {
      service_account = google_service_account.service_account.email
      max_retries     = 1
      timeout         = "1800s"

      containers {
        image = var.dbt_image
        args  = ["run"]
      }
    }
  }
}

# terraform to grant Cloud Run Job runner to service account
resource "google_cloud_run_v2_job_iam_member" "run_job_runner" {
  name     = google_cloud_run_v2_job.dbt.name
  location = google_cloud_run_v2_job.dbt.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.service_account.email}"
}

# terraform to grant Cloud Run developer role to service account
resource "google_project_iam_member" "run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# EVENTARC
resource "google_eventarc_trigger" "trigger" {
  name            = "retail-dga-trigger"
  location        = "eu"
  service_account = google_service_account.service_account.email
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = google_storage_bucket.bucket.name
  }
  destination {
    workflow = google_workflows_workflow.workflow.id
  }
}

# Cloud Build trigger
resource "google_cloudbuild_trigger" "terraform_all_branches" {
  location    = "europe-west1"
  name        = var.cloudbuild_trigger_name
  description = "Run Terraform pipeline on every branch push"

  repository_event_config {
    repository = "projects/retail-etl-489114/locations/europe-west1/connections/retail-etl-git/repositories/anis-m3ir-GCP-ETL"
    push {
      branch = var.cloudbuild_trigger_branch_regex
    }
  }

  filename        = "cloudbuild.yaml"
  service_account = "projects/${var.project_id}/serviceAccounts/retail-etl-sa@${var.project_id}.iam.gserviceaccount.com"

  substitutions = {
    _TF_STATE_BUCKET    = var.tf_state_bucket
    _TF_STATE_PREFIX    = var.tf_state_prefix
    _AR_REGION          = var.region
    _AR_REPO            = var.ar_repo_name
    _DBT_JOB_IMAGE_NAME = "dbt-etl-job"
    _DBT_JOB_IMAGE_TAG  = "latest"
    _GITHUB_OWNER       = var.github_owner
    _GITHUB_REPO        = var.github_repo_name
  }

  depends_on = [google_service_account_iam_member.sa_self_impersonation]
}
