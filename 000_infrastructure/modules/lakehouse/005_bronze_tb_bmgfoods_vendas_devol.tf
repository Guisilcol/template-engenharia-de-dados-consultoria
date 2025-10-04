resource "google_bigquery_table" "bronze_tb_bmgfoods_vendas_devol" {
  project             = var.project_id
  dataset_id          = google_bigquery_dataset.bronze_dataset.dataset_id
  deletion_protection = false
  table_id            = "tb_bmgfoods_vendas_devol"

  external_data_configuration {
    autodetect    = false
    source_format = "PARQUET"

    source_uris = ["gs://${google_storage_bucket.bronze_bucket.name}/bmgfoods_vendas_devol/*"]

    hive_partitioning_options {
      mode                     = "STRINGS"
      source_uri_prefix        = "gs://${google_storage_bucket.bronze_bucket.name}/bmgfoods_vendas_devol"
      require_partition_filter = false
    }
  }

  schema = <<EOF
[
  {
    "name": "apelido",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "idfilial",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "tipo",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "data_emissao",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "documento",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "idemitente",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "razao_social",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "cnpj_cpf",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "grupo",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "subgrupo",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "idproduto",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "idindustria",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "produto",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "tipo_preco",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "quantidade",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "precision": "18",
    "scale": "3"
  },
  {
    "name": "peso_liquido",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "precision": "18",
    "scale": "3"
  },
  {
    "name": "valor_total",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "precision": "18",
    "scale": "3"
  },
  {
    "name": "valor_unitario",
    "type": "NUMERIC",
    "mode": "NULLABLE",
    "precision": "18",
    "scale": "3"
  },
  {
    "name": "estabelecimento",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "arquivo_origem",
    "type": "STRING",
    "mode": "NULLABLE"
  },
  {
    "name": "data_criacao",
    "type": "DATE",
    "mode": "NULLABLE"
  }
]
EOF
}
