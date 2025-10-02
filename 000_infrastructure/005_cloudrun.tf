resource "google_cloud_run_v2_job" "default" {
  name     = "teste-job-tf"
  location = var.region
  project  = var.project_id

  template {
    template {
      service_account = google_service_account.cloud_run_job_service_account.email
      containers {
        image = local.artifact_image_path
        args  = ["python", "000_sample/main.py"]
        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }
    }
  }
}
