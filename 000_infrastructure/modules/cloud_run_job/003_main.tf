resource "google_cloud_run_v2_job" "default" {
  name     = var.name
  location = var.location
  project  = var.project_id

  template {
    template {
      service_account = var.service_account_email
      containers {
        image = var.artifact_image_path
        args  = var.args
        resources {
          limits = {
            cpu    = var.cpu_limit
            memory = var.memory_limit
          }
        }
      }
    }
  }
}
