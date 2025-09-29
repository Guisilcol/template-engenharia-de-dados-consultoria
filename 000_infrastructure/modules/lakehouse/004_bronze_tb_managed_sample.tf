resource "google_bigquery_table" "bronze_tb_managed_sample" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.bronze_dataset.dataset_id
  deletion_protection = false
  table_id            = "tb_managed_sample"

  schema = <<EOF
[
  {
    "name": "id",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The ID"
  },
  {
    "name": "data",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The data"
  }
]
EOF
}
