module "cloud_run_job_sample" {
  source = "./modules/cloud_run_job"

  name                  = "teste-job-tf-v2"
  location              = var.region
  project_id            = var.project_id
  service_account_email = google_service_account.cloud_run_job_service_account.email
  artifact_image_path   = local.artifact_image_path
  args                  = ["python", "000_sample/main.py"]
  cpu_limit             = "1"
  memory_limit          = "512Mi"
}
