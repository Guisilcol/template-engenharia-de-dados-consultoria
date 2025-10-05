# Null resource que sempre executa e cria um arquivo dummy no GCS
# Isso garante que a tabela externa tenha pelo menos um arquivo para ser criada
resource "null_resource" "create_dummy_file" {
  count = var.create_dummy_file ? 1 : 0

  # Trigger que força a execução em todo terraform apply
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      echo " " | gcloud storage cp - gs://${var.bucket_name}/${var.table_prefix}/${var.dummy_partition_name}/.dummy_null_resource
    EOT
  }
}


resource "google_bigquery_table" "external_table" {
  depends_on          = [null_resource.create_dummy_file]
  project             = var.project_id
  dataset_id          = var.dataset_id
  deletion_protection = var.deletion_protection
  table_id            = var.table_id

  external_data_configuration {
    autodetect    = var.autodetect
    source_format = var.source_format

    source_uris = ["gs://${var.bucket_name}/${var.table_prefix}/*"]

    hive_partitioning_options {
      mode                     = var.hive_partitioning_mode
      source_uri_prefix        = "gs://${var.bucket_name}/${var.table_prefix}/"
      require_partition_filter = var.require_partition_filter
    }
  }

  schema = var.schema
}


# Null resource que apaga o arquivo dummy criado anteriormente
# Depende do null resource anterior e da tabela externa
resource "null_resource" "delete_dummy_file" {
  count = var.create_dummy_file ? 1 : 0

  # Trigger que força a execução em todo terraform apply
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOT
      gcloud storage rm gs://${var.bucket_name}/${var.table_prefix}/${var.dummy_partition_name}/.dummy_null_resource || true
    EOT
  }

  depends_on = [
    null_resource.create_dummy_file,
    google_bigquery_table.external_table
  ]
}
