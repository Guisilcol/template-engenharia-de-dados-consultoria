# Módulo para criar tabela gerenciada de exemplo no dataset bronze
module "bronze_tb_managed_sample" {
  source = "./modules/managed_table"

  project_id          = var.project_id
  dataset_id          = google_bigquery_dataset.bronze_dataset.dataset_id
  table_id            = "tb_managed_sample"
  deletion_protection = false
  description         = "Tabela gerenciada de exemplo para testes"

  schema = jsonencode([
    {
      name        = "id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "The ID"
    },
    {
      name        = "data"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "The data"
    }
  ])
}
