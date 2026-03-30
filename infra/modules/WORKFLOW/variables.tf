variable "project_id" {
  description = "GCP project ID"
  type        = string
}
variable "region" {
  description = "GCP region for resources"
  type        = string
}
variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
}
variable "bucket_name" {
  description = "GCS bucket name"
  type        = string
}
variable "dbt_job_name" {
  description = "dbt job name"
  type        = string
}
variable "workflow_name" {
  description = "Workflow name"
  type        = string
}
variable "dbt_image" {
  description = "dbt image"
  type        = string
}
variable "retail_etl_sa_email" {
  description = "Service account email for pipeline orchestration"
  type        = string
}
variable "dbt_runner_secret_id" {
  description = "Secret Manager secret ID for dbt runner credentials"
  type        = string
}
variable "ar_repo_name" {
  description = "Secret Manager secret ID for dbt runner credentials"
  type        = string
} 
variable "github_owner" {
  description = "Githube Owner"
  type        = string
} 
variable "github_repo_name" {
  description = "Cloud Build service account name"
  type        = string
} 
variable "cloudbuild_trigger_branch" {
  description = "Cloud Build service account name"
  type        = string
}

variable "tf_state_bucket" {
description = "TF STATE BUCKET NME"
  type        = string
}

variable "tf_state_prefix" {
  description = "Cloud Build service account name"
  type        = string
}
variable "cloudbuild_sa_id" {
  description = "Cloud Build service account ID"
  type        = string
}