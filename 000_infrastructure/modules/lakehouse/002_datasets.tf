resource "google_bigquery_dataset" "bronze_dataset" {
  project       = var.project_id
  dataset_id    = var.bronze_dataset_name
  friendly_name = var.bronze_dataset_name
  description   = "This is a dataset for bronze data."
  location      = var.region
}

resource "google_bigquery_dataset" "silver_dataset" {
  project       = var.project_id
  dataset_id    = var.silver_dataset_name
  friendly_name = var.silver_dataset_name
  description   = "This is a dataset for silver data."
  location      = var.region
}

resource "google_bigquery_dataset" "gold_dataset" {
  project       = var.project_id
  dataset_id    = var.gold_dataset_name
  friendly_name = var.gold_dataset_name
  description   = "This is a dataset for gold data."
  location      = var.region
}

resource "google_bigquery_dataset" "system_dataset" {
  project       = var.project_id
  dataset_id    = var.system_dataset_name
  friendly_name = var.system_dataset_name
  description   = "This is a dataset for system data (logs, metadata, etc)."
  location      = var.region
}
