# -----------------------------------------------------------------------------
# PROJECT Configuration
# -----------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------------------------

variable "cloudbuild_sa_name" {
  description = "Service account name for Cloud Build"
  type        = string
}

variable "retail_etl_sa_name" {
  description = "Service account name for retail ETL orchestration"
  type        = string
}

variable "dbt_runner_sa_name" {
  description = "Service account name for dbt runner"
  type        = string
}