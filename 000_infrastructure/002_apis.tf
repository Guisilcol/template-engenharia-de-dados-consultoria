# Habilita as APIs necessárias do Google Cloud
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",              # Cloud Run
    "cloudbuild.googleapis.com",       # Cloud Build
    "artifactregistry.googleapis.com", # Artifact Registry
    "logging.googleapis.com",          # Cloud Logging
    "monitoring.googleapis.com"        # Cloud Monitoring
  ])

  project = var.project_id
  service = each.key

  disable_dependent_services = false
  disable_on_destroy         = false
}
