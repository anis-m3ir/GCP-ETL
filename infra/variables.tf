# =============================================================================
# Global Variables - Retail Data Platform
# =============================================================================

# -----------------------------------------------------------------------------
# Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-west1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "koptann"
}

# -----------------------------------------------------------------------------
# Service Account Names
# -----------------------------------------------------------------------------

variable "cloudbuild_sa_name" {
  description = "Name for Cloud Build service account"
  type        = string
  default     = "cloudbuild-sa"
}

variable "retail_etl_sa_name" {
  description = "Name for Retail ETL orchestration service account"
  type        = string
  default     = "retail-etl-sa"
}

variable "dbt_runner_sa_name" {
  description = "Name for dbt runner service account"
  type        = string
  default     = "dbt-runner"
}


variable "bucket_name" {
  description = "GCP project ID"
  type        = string
}

variable "dataset_id" {
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
variable "workflow_name" {
  description = "Workflow name"
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