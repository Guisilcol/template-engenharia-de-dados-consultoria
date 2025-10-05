resource "google_bigquery_table" "managed_table" {
  project             = var.project_id
  dataset_id          = var.dataset_id
  deletion_protection = var.deletion_protection
  table_id            = var.table_id
  description         = var.description
  expiration_time     = var.expiration_time
  labels              = var.labels

  schema = var.schema

  # Configuração opcional de particionamento
  dynamic "time_partitioning" {
    for_each = var.time_partitioning != null ? [var.time_partitioning] : []
    content {
      type                     = time_partitioning.value.type
      field                    = time_partitioning.value.field
      expiration_ms            = time_partitioning.value.expiration_ms
      require_partition_filter = time_partitioning.value.require_partition_filter
    }
  }

  # Configuração opcional de clustering
  clustering = var.clustering
}
