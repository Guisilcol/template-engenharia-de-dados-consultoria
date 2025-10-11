# ============================================================================
# CLOUD RUN SERVICES - DASHBOARDS
# ============================================================================
# Este arquivo define os Cloud Run Services para aplicações Dash (dashboards).
# 
# IMPORTANTE: O Dockerfile em 003_dashboards é COMPLETAMENTE GENÉRICO - não 
# possui CMD/ENTRYPOINT. Todo o comando de inicialização é definido aqui no 
# Terraform via 'command' e 'args', permitindo:
#   - Usar a mesma imagem Docker para múltiplos dashboards
#   - Configurar workers, timeout, etc. por serviço
#   - Máxima flexibilidade na infraestrutura
#
# Para adicionar um novo dashboard:
# 1. Crie uma pasta em 003_dashboards/ (ex: 002_vendas/)
# 2. Crie seu main.py com a aplicação Dash
# 3. Exponha o servidor: server = app.server
# 4. Copie e ajuste este módulo, alterando command/args conforme necessário
# ============================================================================

# Cloud Run Service para Dashboard Dash - Sample
module "dashboard_sample" {
  source = "./modules/cloud_run_service"

  name                  = "dashboard-sample"
  location              = var.region
  project_id            = var.project_id
  service_account_email = google_service_account.cloud_run_job_service_account.email
  container_image       = local.cloud_run_dashboards_artifact_image_path
  container_port        = 8050

  # Comando completo de inicialização do container
  # command: define o executável principal
  # args: argumentos para o comando
  command = ["gunicorn"]
  args = [
    "--bind", "0.0.0.0:8050",
    "--workers", "2",
    "--threads", "4",
    "--timeout", "120",
    "001_sample.main:server"
  ]

  # Recursos
  cpu_limit    = "1"
  memory_limit = "512Mi"

  # Auto-scaling
  min_instances = 0
  max_instances = 10

  # Timeout para requisições
  timeout_seconds = 300

  # Variáveis de ambiente
  env_vars = [
    {
      name  = "DASH_ENV"
      value = "production"
    },
    {
      name  = "PROJECT_ID"
      value = var.project_id
    },
    {
      name  = "REGION"
      value = var.region
    },
    {
      name  = "BRONZE_DATASET_ID"
      value = module.bigquery_lakehouse.bronze_dataset_id
    },
    {
      name  = "SILVER_DATASET_ID"
      value = module.bigquery_lakehouse.silver_dataset_id
    },
    {
      name  = "GOLD_DATASET_ID"
      value = module.bigquery_lakehouse.gold_dataset_id
    }
  ]

  # Acesso não autenticado (pode ser alterado conforme necessidade)
  allow_unauthenticated = true

  # Ingress público
  ingress = "INGRESS_TRAFFIC_ALL"

  # Health checks
  startup_probe = {
    enabled               = true
    path                  = "/"
    initial_delay_seconds = 10
    timeout_seconds       = 3
    period_seconds        = 10
    failure_threshold     = 3
  }

  liveness_probe = {
    enabled               = true
    path                  = "/"
    initial_delay_seconds = 0
    timeout_seconds       = 3
    period_seconds        = 30
    failure_threshold     = 3
  }

  # Labels para organização
  labels = {
    environment = "production"
    app         = "dashboard"
    type        = "sample"
    managed_by  = "terraform"
  }

  depends_on = [
    google_artifact_registry_repository.docker_repo,
    module.bigquery_lakehouse
  ]
}

# Outputs
output "dashboard_sample_url" {
  description = "URL do dashboard sample"
  value       = module.dashboard_sample.service_url
}

output "dashboard_sample_name" {
  description = "Nome do serviço do dashboard sample"
  value       = module.dashboard_sample.service_name
}

# ============================================================================
# EXEMPLO: Como adicionar um novo dashboard
# ============================================================================
# Descomente e ajuste o bloco abaixo para adicionar mais dashboards:
#
# module "dashboard_vendas" {
#   source = "./modules/cloud_run_service"
#
#   name                  = "dashboard-vendas"
#   location              = var.region
#   project_id            = var.project_id
#   service_account_email = google_service_account.cloud_run_job_service_account.email
#   container_image       = local.cloud_run_dashboards_artifact_image_path
#   container_port        = 8050
#
#   # Comando completo de inicialização
#   # IMPORTANTE: Mudar apenas o último item do args (módulo Python)
#   command = ["gunicorn"]
#   args = [
#     "--bind", "0.0.0.0:8050",
#     "--workers", "2",
#     "--threads", "4",
#     "--timeout", "120",
#     "002_vendas.main:server"  # <-- Mudar aqui para o novo módulo
#   ]
#
#   cpu_limit    = "1"
#   memory_limit = "512Mi"
#
#   min_instances = 0
#   max_instances = 10
#
#   timeout_seconds = 300
#
#   env_vars = [
#     {
#       name  = "DASH_ENV"
#       value = "production"
#     },
#     {
#       name  = "PROJECT_ID"
#       value = var.project_id
#     },
#     {
#       name  = "REGION"
#       value = var.region
#     }
#   ]
#
#   allow_unauthenticated = true
#   ingress               = "INGRESS_TRAFFIC_ALL"
#
#   startup_probe = {
#     enabled               = true
#     path                  = "/"
#     initial_delay_seconds = 10
#     timeout_seconds       = 3
#     period_seconds        = 10
#     failure_threshold     = 3
#   }
#
#   liveness_probe = {
#     enabled               = true
#     path                  = "/"
#     initial_delay_seconds = 0
#     timeout_seconds       = 3
#     period_seconds        = 30
#     failure_threshold     = 3
#   }
#
#   labels = {
#     environment = "production"
#     app         = "dashboard"
#     type        = "vendas"
#     managed_by  = "terraform"
#   }
#
#   depends_on = [
#     google_artifact_registry_repository.docker_repo,
#     module.bigquery_lakehouse
#   ]
# }
#
# output "dashboard_vendas_url" {
#   description = "URL do dashboard de vendas"
#   value       = module.dashboard_vendas.service_url
# }
# ============================================================================
