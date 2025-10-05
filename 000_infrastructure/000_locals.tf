locals {
  artifact_image_path = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}/${var.artifact_image_name_to_cloud_run}"

  # Variáveis de ambiente comuns para todos os Cloud Run Jobs
  common_job_env_vars = [
    {
      name  = "RECEPCTION_BUCKET"
      value = var.reception_bucket_name
    },
    {
      name  = "BRONZE_BUCKET"
      value = var.bronze_bucket_name
    },
    {
      name  = "SILVER_BUCKET"
      value = var.silver_bucket_name
    },
    {
      name  = "GOLD_BUCKET"
      value = var.gold_bucket_name
    },
    {
      name  = "SYSTEM_DATASET_ID"
      value = module.bigquery_lakehouse.system_dataset_id
    },
    {
      name  = "BRONZE_DATASET_ID"
      value = module.bigquery_lakehouse.bronze_dataset_id
    },
    {
      name  = "SILVER_DATASET_ID"
      value = module.bigquery_lakehouse.silver_dataset_id
    },
    {
      name  = "GOLD_DATASET_ID"
      value = module.bigquery_lakehouse.gold_dataset_id
    },
    {
      name  = "PROJECT_ID"
      value = var.project_id
    },
    {
      name  = "REGION"
      value = var.region
    }
  ]
}
