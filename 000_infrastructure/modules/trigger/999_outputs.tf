output "scheduler_job_id" {
  description = "ID do Cloud Scheduler job criado"
  value       = var.target_type == "workflow" ? (length(google_cloud_scheduler_job.workflow_trigger) > 0 ? google_cloud_scheduler_job.workflow_trigger[0].id : null) : (length(google_cloud_scheduler_job.cloud_run_job_trigger) > 0 ? google_cloud_scheduler_job.cloud_run_job_trigger[0].id : null)
}

output "scheduler_job_name" {
  description = "Nome do Cloud Scheduler job criado"
  value       = var.target_type == "workflow" ? (length(google_cloud_scheduler_job.workflow_trigger) > 0 ? google_cloud_scheduler_job.workflow_trigger[0].name : null) : (length(google_cloud_scheduler_job.cloud_run_job_trigger) > 0 ? google_cloud_scheduler_job.cloud_run_job_trigger[0].name : null)
}

output "target_type" {
  description = "Tipo de alvo configurado"
  value       = var.target_type
}

output "schedule" {
  description = "Expressão cron do agendamento"
  value       = var.schedule
}
