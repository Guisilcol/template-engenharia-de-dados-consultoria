resource "google_storage_bucket" "reception_bucket" {
  name          = "${var.reception_bucket_name}-${var.project_id}"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket" "bronze_bucket" {
  name          = "${var.bronze_bucket_name}-${var.project_id}"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket" "silver_bucket" {
  name          = "${var.silver_bucket_name}-${var.project_id}"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket" "gold_bucket" {
  name          = "${var.gold_bucket_name}-${var.project_id}"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}
