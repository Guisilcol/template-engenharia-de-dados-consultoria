terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}
