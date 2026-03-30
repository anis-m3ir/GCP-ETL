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
########### CREATE BUCKET
resource "google_storage_bucket" "data_bucket" {
  name          = var.bucket_name
  location      = "EU"
  force_destroy = true
}

########### CREATE DATASET
resource "google_bigquery_dataset" "dataset" {
  dataset_id    = var.dataset_id
  friendly_name = "Retail Dataset"
  description   = "Retail Dataset"
  location      = "EU"
}

resource "time_sleep" "wait_for_dataset_creation" {
  create_duration = "90s" 
}

########### create table in bigquery
resource "google_bigquery_table" "raw_country" {
  dataset_id = var.dataset_id
  table_id   = "raw_country"
  schema     = <<EOF
  [
    {
      "name": "id",
      "type": "STRING"
    },
    {
      "name": "iso",
      "type": "STRING"
    },
    {
      "name": "name",
      "type": "STRING"
    },
    {
      "name": "nicename",
      "type": "STRING"
    },
    {
      "name": "iso3",
      "type": "STRING"
    },
    {
      "name": "numcode",
      "type": "STRING"
    },
    {
      "name": "phonecode",
      "type": "STRING"
    }]
  EOF
  depends_on = [time_sleep.wait_for_dataset_creation]
}
# terraform to create table raw_invoice  InvoiceNo,StockCode,Description,Quantity,InvoiceDate,UnitPrice,CustomerID,Country
resource "google_bigquery_table" "raw_invoice" {
  dataset_id = var.dataset_id
  table_id   = "raw_invoice"
  schema     = <<EOF
  [
    {
      "name": "InvoiceNo",
      "type": "STRING"
    },
    {
      "name": "StockCode",
      "type": "STRING"
    },
    {
      "name": "Description",
      "type": "STRING"
    },
    {
      "name": "Quantity",
      "type": "STRING"
    },
    {
      "name": "InvoiceDate",
      "type": "STRING"
    },
    {
      "name": "UnitPrice",
      "type": "STRING"
    },
    {
      "name": "CustomerID",
      "type": "STRING"
    },
    {
      "name": "Country",
      "type": "STRING"
    }]
  EOF
  depends_on = [time_sleep.wait_for_dataset_creation]
}

# terraform to create Artifact Registry Docker repository for dbt images
resource "google_artifact_registry_repository" "dbt_images" {
  location      = var.region
  repository_id = var.ar_repo_name
  description   = "dbt images"
  format        = "DOCKER"
}

