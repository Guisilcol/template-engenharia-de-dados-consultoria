resource "google_cloud_run_v2_service" "default" {
  name                = var.name
  location            = var.location
  project             = var.project_id
  deletion_protection = false
  ingress             = var.ingress

  labels = var.labels

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    timeout = "${var.timeout_seconds}s"

    containers {
      image   = var.container_image
      command = var.command
      args    = var.args

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }

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

      # Startup probe
      dynamic "startup_probe" {
        for_each = var.startup_probe.enabled ? [1] : []
        content {
          initial_delay_seconds = var.startup_probe.initial_delay_seconds
          timeout_seconds       = var.startup_probe.timeout_seconds
          period_seconds        = var.startup_probe.period_seconds
          failure_threshold     = var.startup_probe.failure_threshold

          http_get {
            path = var.startup_probe.path
            port = var.container_port
          }
        }
      }

      # Liveness probe
      dynamic "liveness_probe" {
        for_each = var.liveness_probe.enabled ? [1] : []
        content {
          initial_delay_seconds = var.liveness_probe.initial_delay_seconds
          timeout_seconds       = var.liveness_probe.timeout_seconds
          period_seconds        = var.liveness_probe.period_seconds
          failure_threshold     = var.liveness_probe.failure_threshold

          http_get {
            path = var.liveness_probe.path
            port = var.container_port
          }
        }
      }
    }

    # VPC Connector
    dynamic "vpc_access" {
      for_each = var.vpc_connector_name != null ? [1] : []
      content {
        connector = var.vpc_connector_name
        egress    = var.vpc_egress
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# IAM policy to allow unauthenticated access
resource "google_cloud_run_v2_service_iam_member" "noauth" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = var.location
  name     = google_cloud_run_v2_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
