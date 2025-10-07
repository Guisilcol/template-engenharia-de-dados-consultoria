# Service Account para o Cloud Run Job
resource "google_service_account" "cloud_run_job_service_account" {
  account_id = "cloud-run-job-service-account"
}

# IAM bindings para a Service Account
resource "google_project_iam_member" "cloud_run_job_permissions" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/bigquery.dataEditor",
    "roles/bigquery.jobUser",
    "roles/storage.objectAdmin",
    "roles/run.invoker",
    "roles/run.developer",
    "roles/run.viewer",
    "roles/workflows.invoker",
    "roles/run.invoker",
    "roles/secretmanager.secretAccessor"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloud_run_job_service_account.email}"
}

# HMAC Key para a Service Account
resource "google_storage_hmac_key" "cloud_run_job_hmac_key" {
  service_account_email = google_service_account.cloud_run_job_service_account.email
  project               = var.project_id
}
