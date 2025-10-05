# Módulo para criar tabela externa no BigQuery
module "bronze_tb_externa_exemplo" {
  source = "./modules/external_table"

  project_id          = var.project_id
  dataset_id          = google_bigquery_dataset.bronze_dataset.dataset_id
  table_id            = "tb_externa_exemplo"
  bucket_name         = google_storage_bucket.bronze_bucket.name
  table_prefix        = "tb_externa_exemplo"
  deletion_protection = false

  source_format              = "PARQUET"
  autodetect                 = false
  hive_partitioning_mode     = "STRINGS"
  require_partition_filter   = false
  create_dummy_file          = true
  dummy_partition_name       = "partition=dummy"

  schema = jsonencode([
    {
      name = "id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "data"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "partition"
      type = "STRING"
      mode = "NULLABLE"
    }
  ])
}
