
module "some_secret" {
    source = "./modules/secret_manager"

    project_id = var.project_id
    secrets = [
        {
            secret_id  = "my-secret"
            description = "This is a secret created by Terraform"
        }
    ]
}

# Secret para armazenar o HMAC Access ID
module "hmac_access_id_secret" {
    source = "./modules/secret_manager"

    project_id   = var.project_id
    secret_value = google_storage_hmac_key.cloud_run_job_hmac_key.access_id
    secrets = [
        {
            secret_id   = "cloud-run-job-hmac-access-id"
            description = "HMAC Access ID for cloud_run_job_service_account"
            labels = {
                service_account = "cloud-run-job"
                type           = "hmac-access-id"
            }
        }
    ]
}

# Secret para armazenar o HMAC Secret
module "hmac_secret_key_secret" {
    source = "./modules/secret_manager"

    project_id   = var.project_id
    secret_value = google_storage_hmac_key.cloud_run_job_hmac_key.secret
    secrets = [
        {
            secret_id   = "cloud-run-job-hmac-secret"
            description = "HMAC Secret Key for cloud_run_job_service_account"
            labels = {
                service_account = "cloud-run-job"
                type           = "hmac-secret"
            }
        }
    ]
}