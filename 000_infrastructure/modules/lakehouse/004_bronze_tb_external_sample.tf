# Null resource que sempre executa e cria um arquivo dummy no GCS
resource "null_resource" "create_dummy_file" {
  # Trigger que força a execução em todo terraform apply
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      echo " " | gcloud storage cp - gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample/partition=dummy/.dummy_null_resource
    EOT
  }

  depends_on = [google_storage_bucket.bronze_bucket]
}


resource "google_bigquery_table" "bronze_tb_external_sample_v4" {
  depends_on          = [null_resource.create_dummy_file]
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.bronze_dataset.dataset_id
  deletion_protection = false
  table_id            = "tb_external_sample"


  external_data_configuration {
    autodetect    = false
    source_format = "PARQUET"

    source_uris = ["gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample/*"]

    hive_partitioning_options {
      mode                     = "STRINGS"
      source_uri_prefix        = "gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample/"
      require_partition_filter = false
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
  },
  {
    "name": "partition",
    "type": "STRING",
    "mode": "NULLABLE"
  }
]
EOF
}


# Null resource que apaga o arquivo criado pelo null resource anterior
# Depende do null resource anterior e da tabela bronze_tb_external_sample_v4
resource "null_resource" "delete_dummy_file" {
  # Trigger que força a execução em todo terraform apply
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud storage rm gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample/partition=dummy/.dummy_null_resource || true
    EOT
  }

  depends_on = [
    null_resource.create_dummy_file,
    google_bigquery_table.bronze_tb_external_sample_v4
  ]
}
