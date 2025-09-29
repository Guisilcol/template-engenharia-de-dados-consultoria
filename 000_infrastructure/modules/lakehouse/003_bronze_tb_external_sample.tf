resource "google_bigquery_table" "bronze_tb_external_sample" {
  project           = var.project_id
  dataset_id        = google_bigquery_dataset.bronze_dataset.dataset_id
  deletion_protection = false
  table_id          = "tb_external_sample"

  external_data_configuration {
    autodetect      = false
    source_format   = "PARQUET"

    source_uris     = ["gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample"]

    hive_partitioning_options {
      mode              = "STRINGS"
      # source_uri_prefix = "gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample"
    }
  }

  schema = <<EOF
[
  {
    "name": "id",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "data",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}