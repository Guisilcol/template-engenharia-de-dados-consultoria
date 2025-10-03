output "workflow_id" {
  description = "The unique identifier of the workflow."
  value       = google_workflows_workflow.default.id
}

output "workflow_name" {
  description = "The name of the workflow."
  value       = google_workflows_workflow.default.name
}

output "workflow_revision_id" {
  description = "The revision ID of the workflow."
  value       = google_workflows_workflow.default.revision_id
}

output "workflow_state" {
  description = "The state of the workflow."
  value       = google_workflows_workflow.default.state
}

output "workflow_create_time" {
  description = "The timestamp of when the workflow was created."
  value       = google_workflows_workflow.default.create_time
}

output "workflow_update_time" {
  description = "The timestamp of when the workflow was last updated."
  value       = google_workflows_workflow.default.update_time
}
