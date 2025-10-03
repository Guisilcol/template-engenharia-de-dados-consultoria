module "sample_workflow" {
  source = "./modules/workflow"

  name                  = "sample-workflow"
  location              = var.region
  project_id            = var.project_id
  service_account_email = google_service_account.cloud_run_job_service_account.email
  workflow_yaml_path    = "${path.module}/../002_orquestration/001_sample_workflow.yaml"

  # Variables to be replaced in the YAML template using templatefile
  template_vars = {
    project_id = var.project_id
    region     = var.region
  }

  description = "Sample workflow created from template"

  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
