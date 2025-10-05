# Exemplo de Job usando apenas as variáveis de ambiente comuns
module "cloud_run_job_sample_v3" {
  source = "./modules/cloud_run_job"

  name                  = "teste-job-tf-v3"
  location              = var.region
  project_id            = var.project_id
  service_account_email = google_service_account.cloud_run_job_service_account.email
  artifact_image_path   = local.artifact_image_path
  args                  = ["python", "000_sample/main.py"]
  cpu_limit             = "1"
  memory_limit          = "512Mi"
  max_retries           = 0
  env_vars              = concat(
    local.common_job_env_vars,
    [
      {
        name  = "SAMPLE_VAR"
        value = "sample_value"
      }
    ]
  )
}
