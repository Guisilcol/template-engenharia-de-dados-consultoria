
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