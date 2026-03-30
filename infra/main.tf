# =============================================================================
# RETAIL DATA PLATFORM - ROOT MODULE
# =============================================================================
# Domain-Driven Architecture - Business Capability Modules
#
# This root module composes three domain modules:
# - platform: Infrastructure provisioning (BUILD)
# - pipeline: Data orchestration & execution (RUN)  
# - observability: Monitoring & quality (OBSERVE)
# =============================================================================

terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# =============================================================================
# MODULE DECLARATIONS - Domain-Driven Architecture
# =============================================================================
# Modules are organized by BUSINESS CAPABILITY (what they DO):
# - platform: Infrastructure provisioning (IAM + storage + container infra)
# - pipeline: Data orchestration & execution (workflows + triggers + compute)
# - observability: Monitoring & quality (cross-cutting concerns)
#
# This follows Domain-Driven Design principles, similar to microservices
# organized by business domain rather than technical layers.
# =============================================================================

# -----------------------------------------------------------------------------
# Platform Module - Infrastructure Foundation
# -----------------------------------------------------------------------------
# Business Domain: Infrastructure provisioning and identity management
# 
# Creates all foundational resources including:
# - IAM: Service accounts, role bindings, Secret Manager
# - Storage: GCS bucket, BigQuery dataset, raw tables
# - Container Infrastructure: Artifact Registry
#
# Dependencies: None (foundational module)

module "IAM-SA" {
  source = "./modules/IAM-SA"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  # IAM configuration
  cloudbuild_sa_name = var.cloudbuild_sa_name
  retail_etl_sa_name = var.retail_etl_sa_name
  dbt_runner_sa_name = var.dbt_runner_sa_name
}

module "STORAGE" {
  source = "./modules/STORAGE"

  bucket_name = var.bucket_name
  dataset_id = var.dataset_id
  region = var.region
  ar_repo_name = var.ar_repo_name
  dbt_job_name = var.dbt_job_name
  dbt_image = var.dbt_image
  retail_etl_sa_email = var.retail_etl_sa_email
}

module "WORKFLOW" {
  source = "./modules/WORKFLOW"

  project_id = var.project_id
  dbt_job_name = var.dbt_job_name
  workflow_name = var.workflow_name
  bucket_name = var.bucket_name
  dataset_id = var.dataset_id
  region = var.region
  dbt_image = var.dbt_image
  retail_etl_sa_email = var.retail_etl_sa_email
  dbt_runner_secret_id = module.IAM-SA.dbt_runner_secret_id
  ar_repo_name = var.ar_repo_name
  github_owner = var.github_owner
  github_repo_name = var.github_repo_name
  cloudbuild_trigger_branch = var.cloudbuild_trigger_branch
  tf_state_bucket = var.tf_state_bucket
  tf_state_prefix = var.tf_state_prefix
  cloudbuild_sa_id    = module.IAM-SA.cloudbuild_sa_id
}