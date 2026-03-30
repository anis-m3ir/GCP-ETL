variable "bucket_name" {
  description = "GCP project ID"
  type        = string
}
variable "dataset_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP project ID"
  type        = string
}

variable "ar_repo_name" {
  description = "GCP project ID"
  type        = string
}

variable "dbt_job_name" {
  description = "GCP project ID"
  type        = string
}

variable "dbt_image" {
  description = "GCP project ID"
  type        = string
}

variable "retail_etl_sa_email" {
  description = "Service account email for pipeline orchestration"
  type        = string
}