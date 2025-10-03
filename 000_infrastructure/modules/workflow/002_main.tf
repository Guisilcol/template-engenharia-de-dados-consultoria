resource "google_workflows_workflow" "default" {
  name            = var.name
  region          = var.location
  project         = var.project_id
  description     = var.description
  service_account = var.service_account_email
  labels          = var.labels

  source_contents = templatefile(var.workflow_yaml_path, var.template_vars)
}
