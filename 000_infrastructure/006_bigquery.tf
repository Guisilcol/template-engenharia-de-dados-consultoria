module "bigquery_lakehouse" {
  source                = "./modules/lakehouse"
  project_id            = var.project_id
  region                = var.region
  bronze_dataset_name   = var.bronze_dataset_name
  silver_dataset_name   = var.silver_dataset_name
  gold_dataset_name     = var.gold_dataset_name
  reception_bucket_name = var.reception_bucket_name
  bronze_bucket_name    = var.bronze_bucket_name
  silver_bucket_name    = var.silver_bucket_name
  gold_bucket_name      = var.gold_bucket_name
}
