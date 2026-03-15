variable "project_id" {
  type        = string
  default     = "retail-etl-489114"
  description = "The project id"
}

variable "region" {
  type        = string
  default     = "europe-west1"
  description = "Region for regional GCP resources"
}

variable "dbt_job_name" {
  type        = string
  default     = "retail-etl-dbt-job"
  description = "Cloud Run job name that executes dbt"
}

variable "dbt_image" {
  type        = string
  default     = "europe-west1-docker.pkg.dev/retail-etl-489114/dbt-images/dbt-etl-job:latest"
  description = "Container image used by Cloud Run Job to run dbt with BigQuery"
}


variable "tf_state_bucket" {
  type        = string
  default     = "retail-etl-tfstate-ag"
  description = "GCS bucket used by Terraform remote state"
}

variable "tf_state_prefix" {
  type        = string
  default     = "terraform/infra"
  description = "Prefix/path used in GCS backend for Terraform state"
}

variable "ar_repo_name" {
  type        = string
  default     = "dbt-images"
  description = "Artifact Registry Docker repo for dbt images"
}

variable "github_owner" {
  type        = string
  default     = "anis-m3ir"
  description = "GitHub owner"
}

variable "github_repo_name" {
  type        = string
  default     = "GCP-ETL"
  description = "GitHub repository name"
}

variable "cloudbuild_trigger_name" {
    type = string
    default  = "retail-etl-all-branches"
            description = "Cloud Build trigger name for Terraform pipeline"
}

variable "cloudbuild_trigger_branch_regex" {
    type = string
    default  = ".*"
}


