resource "google_storage_bucket_object" "tb_external_sample_dummy_v3" {
  name    = "tb_external_sample/partition=dummy/.dummy"
  content = " "
  bucket  = google_storage_bucket.bronze_bucket.name
  
}


resource "google_bigquery_table" "bronze_tb_external_sample_v3" {
  depends_on = [ google_storage_bucket_object.tb_external_sample_dummy_v3 ]
  project           = var.project_id
  dataset_id        = google_bigquery_dataset.bronze_dataset.dataset_id
  deletion_protection = false
  table_id          = "tb_external_sample"


  external_data_configuration {
    autodetect      = false
    source_format   = "PARQUET"

    source_uris     = ["gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample/*"]

    hive_partitioning_options {
      mode              = "STRINGS"
      source_uri_prefix = "gs://${google_storage_bucket.bronze_bucket.name}/tb_external_sample/"
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

  # Delete the temporary dummy object right after the table is created
  provisioner "local-exec" {
    # Ensure we use bash and the correct project context without mutating global gcloud config
    interpreter = ["/bin/bash", "-c"]
    environment = {
      CLOUDSDK_CORE_PROJECT = var.project_id
    }
    command = "gcloud storage rm -q gs://${google_storage_bucket.bronze_bucket.name}/${google_storage_bucket_object.tb_external_sample_dummy_v3.name}"
  }
}