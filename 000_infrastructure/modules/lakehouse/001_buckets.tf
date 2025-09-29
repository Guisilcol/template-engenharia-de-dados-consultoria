resource "google_storage_bucket" "reception_bucket" {
  name          = "${var.project_id}-${var.reception_bucket_name}"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket" "bronze_bucket" {
  name          = "${var.project_id}-${var.bronze_bucket_name}"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket" "silver_bucket" {
  name          = "${var.project_id}-${var.silver_bucket_name}"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket" "gold_bucket" {
  name          = "${var.project_id}-${var.gold_bucket_name}"
  project       = var.project_id
  location      = var.region
  force_destroy = true
}
