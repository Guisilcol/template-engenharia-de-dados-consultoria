# Cloud Scheduler para disparar Workflow
resource "google_cloud_scheduler_job" "workflow_trigger" {
  count = var.target_type == "workflow" ? 1 : 0

  name             = var.name
  description      = var.description
  schedule         = var.schedule
  time_zone        = var.time_zone
  project          = var.project_id
  region           = var.region
  paused           = var.paused
  attempt_deadline = var.attempt_deadline

  retry_config {
    retry_count          = var.retry_config.retry_count
    max_retry_duration   = var.retry_config.max_retry_duration
    min_backoff_duration = var.retry_config.min_backoff_duration
    max_backoff_duration = var.retry_config.max_backoff_duration
    max_doublings        = var.retry_config.max_doublings
  }

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.workflow_location}/workflows/${var.workflow_name}/executions"
    body        = base64encode(jsonencode({
      argument = var.workflow_argument
    }))

    oauth_token {
      service_account_email = var.service_account_email
    }

    headers = {
      "Content-Type" = "application/json"
    }
  }
}

# Cloud Scheduler para disparar Cloud Run Job
resource "google_cloud_scheduler_job" "cloud_run_job_trigger" {
  count = var.target_type == "cloud_run_job" ? 1 : 0

  name             = var.name
  description      = var.description
  schedule         = var.schedule
  time_zone        = var.time_zone
  project          = var.project_id
  region           = var.region
  paused           = var.paused
  attempt_deadline = var.attempt_deadline

  retry_config {
    retry_count          = var.retry_config.retry_count
    max_retry_duration   = var.retry_config.max_retry_duration
    min_backoff_duration = var.retry_config.min_backoff_duration
    max_backoff_duration = var.retry_config.max_backoff_duration
    max_doublings        = var.retry_config.max_doublings
  }

  http_target {
    http_method = "POST"
    uri         = "https://${var.cloud_run_job_location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${var.cloud_run_job_name}:run"

    oauth_token {
      service_account_email = var.service_account_email
    }

    headers = {
      "Content-Type" = "application/json"
    }
  }
}
