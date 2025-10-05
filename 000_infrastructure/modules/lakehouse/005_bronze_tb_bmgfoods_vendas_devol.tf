# Módulo para criar tabela externa de vendas e devoluções BMG Foods
module "bronze_tb_bmgfoods_vendas_devol" {
  source = "./modules/external_table"

  project_id          = var.project_id
  dataset_id          = google_bigquery_dataset.bronze_dataset.dataset_id
  table_id            = "tb_bmgfoods_vendas_devol"
  bucket_name         = google_storage_bucket.bronze_bucket.name
  table_prefix        = "bmgfoods_vendas_devol"
  deletion_protection = false

  source_format            = "PARQUET"
  autodetect               = false
  hive_partitioning_mode   = "STRINGS"
  require_partition_filter = false
  create_dummy_file        = false # Não cria arquivo dummy para esta tabela

  schema = jsonencode([
    {
      name = "apelido"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "idfilial"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "tipo"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "data_emissao"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "documento"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "idemitente"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "razao_social"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "cnpj_cpf"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "grupo"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "subgrupo"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "idproduto"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "idindustria"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "produto"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "tipo_preco"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "quantidade"
      type = "FLOAT64"
      mode = "NULLABLE"
    },
    {
      name = "peso_liquido"
      type = "FLOAT64"
      mode = "NULLABLE"
    },
    {
      name = "valor_total"
      type = "FLOAT64"
      mode = "NULLABLE"
    },
    {
      name = "valor_unitario"
      type = "FLOAT64"
      mode = "NULLABLE"
    },
    {
      name = "estabelecimento"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "data_criacao"
      type = "DATE"
      mode = "NULLABLE"
    },
    {
      name = "arquivo_origem"
      type = "STRING"
      mode = "NULLABLE"
    }
  ])
}
