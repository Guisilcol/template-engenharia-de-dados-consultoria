resource "google_storage_bucket_object" "tb_external_sample_dummy_v3" {
  name    = "tb_external_sample/partition=dummy/.dummy"
  content = " "
  bucket  = google_storage_bucket.bronze_bucket.name

  lifecycle {
    # Garante que o dummy seja criado antes de destruir o antigo
    create_before_destroy = true
  }
}

resource "google_bigquery_table" "bronze_tb_external_sample_v4" {
  depends_on          = [google_storage_bucket_object.tb_external_sample_dummy_v3]
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

  lifecycle {
    # Garante que o dummy exista antes da tabela ser recriada
    create_before_destroy = true
  }

  # Cria o dummy antes da tabela ser criada/recriada
  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    environment = {
      CLOUDSDK_CORE_PROJECT = var.project_id
    }
    command = <<-EOT
      gcloud storage cp -q <(echo " ") gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample/partition=dummy/.dummy || true
    EOT
  }

  # Remove o dummy após a tabela ser criada/alterada com sucesso
  provisioner "local-exec" {
    when        = create
    interpreter = ["/bin/bash", "-c"]
    environment = {
      CLOUDSDK_CORE_PROJECT = var.project_id
    }
    command = "gcloud storage rm -q gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample/partition=dummy/.dummy || true"
  }

  # Remove o dummy antes da tabela ser destruída (cleanup)
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    environment = {
      CLOUDSDK_CORE_PROJECT = self.project
    }
    command = "gcloud storage rm -q gs://${var.bronze_bucket_name}/tb_external_sample/partition=dummy/.dummy || true"
  }
}
