resource "google_cloud_run_v2_job" "default" {
  name                = var.name
  location            = var.location
  project             = var.project_id
  deletion_protection = false

  template {
    template {
      max_retries     = var.max_retries
      service_account = var.service_account_email
      containers {
        image = var.artifact_image_path
        args  = var.args
        
        # Environment variables regulares
        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.value.name
            value = env.value.value
          }
        }

        # Environment variables a partir de secrets
        dynamic "env" {
          for_each = var.secrets
          content {
            name = env.value.name
            value_source {
              secret_key_ref {
                secret  = env.value.secret_id
                version = env.value.version
              }
            }
          }
        }

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
