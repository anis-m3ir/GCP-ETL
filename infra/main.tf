# --- STORAGE & BIGQUERY ---

# GCS bucket for raw data
resource "google_storage_bucket" "bucket" {
  name          = "retail-etl-dga"
  location      = "EU"
  force_destroy = true
}

# BigQuery dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id    = "retail_dga"
  friendly_name = "Retail Dataset"
  description   = "Retail Dataset"
  location      = "EU"
}

# Raw country reference table
resource "google_bigquery_table" "raw_country" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "raw_country"
  schema     = <<EOF
  [
    {"name": "id",        "type": "STRING", "mode": "NULLABLE"},
    {"name": "iso",       "type": "STRING", "mode": "NULLABLE"},
    {"name": "name",      "type": "STRING", "mode": "NULLABLE"},
    {"name": "nicename",  "type": "STRING", "mode": "NULLABLE"},
    {"name": "iso3",      "type": "STRING", "mode": "NULLABLE"},
    {"name": "numcode",   "type": "STRING", "mode": "NULLABLE"},
    {"name": "phonecode", "type": "STRING", "mode": "NULLABLE"}
  ]
  EOF
}

# Raw invoice transactions table
resource "google_bigquery_table" "raw_invoice" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "raw_invoice"
  schema     = <<EOF
  [
    {"name": "InvoiceNo",   "type": "STRING", "mode": "NULLABLE"},
    {"name": "StockCode",   "type": "STRING", "mode": "NULLABLE"},
    {"name": "Description", "type": "STRING", "mode": "NULLABLE"},
    {"name": "Quantity",    "type": "STRING", "mode": "NULLABLE"},
    {"name": "InvoiceDate", "type": "STRING", "mode": "NULLABLE"},
    {"name": "UnitPrice",   "type": "STRING", "mode": "NULLABLE"},
    {"name": "CustomerID",  "type": "STRING", "mode": "NULLABLE"},
    {"name": "Country",     "type": "STRING", "mode": "NULLABLE"}
  ]
  EOF
}

# --- SERVICES & REPOSITORY ---

resource "google_project_service" "bigquery_api" {
  service = "bigquery.googleapis.com"
}

resource "google_project_service" "storage_api" {
  service = "storage.googleapis.com"
}

resource "google_project_service" "eventarc_api" {
  service = "eventarc.googleapis.com"
}

resource "google_project_service" "workflows_api" {
  service = "workflows.googleapis.com"
}

resource "google_project_service" "pubsub_api" {
  service = "pubsub.googleapis.com"
}

resource "google_project_service" "service" {
  service = "iam.googleapis.com"
}

resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}

resource "google_project_service" "cloudbuild_api" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "artifact_registry_api" {
  service = "artifactregistry.googleapis.com"
}

resource "google_artifact_registry_repository" "dbt_images" {
  location      = var.region
  repository_id = var.ar_repo_name
  description   = "dbt images"
  format        = "DOCKER"
}

# --- IAM & SECURITY ---

resource "google_service_account" "service_account" {
  account_id   = "retail-etl-sa"
  display_name = "Retail ETL SA"
}

resource "google_project_iam_member" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "eventarc_admin" {
  project = var.project_id
  role    = "roles/eventarc.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

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

resource "google_project_iam_member" "logging_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "workflows_admin" {
  project = var.project_id
  role    = "roles/workflows.admin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "iam_sa_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Self-impersonation pour Cloud Build trigger
resource "google_service_account_iam_member" "sa_self_impersonation" {
  service_account_id = google_service_account.service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.service_account.email}"
}

# Pub/Sub publisher pour le SA GCS système (Eventarc)
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

resource "google_project_iam_member" "gcs_pubsub_publishing" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# --- SECRET MANAGER ---

resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "dbt_keyfile" {
  secret_id  = "dbt-service-account-key"
  depends_on = [google_project_service.secretmanager]

  replication {
    auto {}
  }

  labels = {
    managed_by = "terraform"
    component  = "dbt"
  }
}

resource "google_secret_manager_secret_version" "dbt_keyfile_version" {
  secret      = google_secret_manager_secret.dbt_keyfile.id
  secret_data = "placeholder"
}

resource "google_secret_manager_secret_iam_member" "dbt_secret_accessor" {
  secret_id = google_secret_manager_secret.dbt_keyfile.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.service_account.email}"
}

# --- COMPUTE (CLOUD RUN JOB) ---

resource "google_cloud_run_v2_job" "dbt" {
  name     = var.dbt_job_name
  location = var.region

  depends_on = [
    google_project_service.artifact_registry_api,
    google_artifact_registry_repository.dbt_images
  ]

  lifecycle {
    ignore_changes = [template[0].template[0].containers[0].image]
  }

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

resource "google_cloud_run_v2_job_iam_member" "run_job_runner" {
  name     = google_cloud_run_v2_job.dbt.name
  location = google_cloud_run_v2_job.dbt.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.service_account.email}"
}

# --- ORCHESTRATION & TRIGGERS ---

resource "google_workflows_workflow" "workflow" {
  name            = "retail-dga-workflow"
  description     = "Retail Dataset Workflow"
  source_contents = local.workflow_yaml
  region          = var.region
  service_account = google_service_account.service_account.email
}

resource "google_eventarc_trigger" "trigger" {
  name            = "retail-dga-trigger"
  location        = "eu"
  service_account = google_service_account.service_account.email
  depends_on      = [google_project_iam_member.gcs_pubsub_publishing]

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
