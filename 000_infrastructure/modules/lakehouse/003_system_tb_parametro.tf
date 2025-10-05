# Módulo para criar tabela de parâmetros do sistema
module "system_tb_parametro" {
  source = "./modules/managed_table"

  project_id          = var.project_id
  dataset_id          = google_bigquery_dataset.system_dataset.dataset_id
  table_id            = "tb_parametro"
  deletion_protection = false
  description         = "Tabela de parâmetros e configurações do sistema"

  schema = jsonencode([
    {
      name                   = "uuid"
      type                   = "STRING"
      mode                   = "REQUIRED"
      description            = "Unique identifier (UUID)"
      defaultValueExpression = "GENERATE_UUID()"
    },
    {
      name        = "codigo_parametro"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique parameter code"
    },
    {
      name        = "parametro"
      type        = "JSON"
      mode        = "NULLABLE"
      description = "Parameter data in JSON format"
    },
    {
      name                   = "datahora_criacao"
      type                   = "TIMESTAMP"
      mode                   = "REQUIRED"
      description            = "Creation timestamp"
      defaultValueExpression = "CURRENT_TIMESTAMP()"
    },
    {
      name        = "datahora_alteracao"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "Last update timestamp"
    }
  ])
}
