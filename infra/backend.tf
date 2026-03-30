# =============================================================================
# Terraform Backend Configuration - GCS Remote State
# =============================================================================
# This file configures remote state storage in Google Cloud Storage
# 
# Benefits:
# - Team collaboration (shared state)
# - State locking (prevents concurrent modifications)
# - Versioning (state history)
# - Security (encrypted at rest)
#
# Prerequisites:
# 1. Create GCS bucket for state:
#    gcloud storage buckets create gs://YOUR-TF-STATE-BUCKET \
#      --location=EU \
#      --uniform-bucket-level-access
#
# 2. Initialize with backend config:
#    terraform init \
#      -backend-config="bucket=YOUR-TF-STATE-BUCKET" \
#      -backend-config="prefix=terraform/infra"
# =============================================================================

terraform {
  backend "gcs" {
    # Configured via -backend-config flags
    # bucket = "retail-etl-tfstate"
    # prefix = "terraform/infra"
  }
}

# =============================================================================
# Note: For local development/testing, you can comment out the backend block
# above and Terraform will use local state storage instead.
# =============================================================================
