# =============================================================================
# MONITORING - Sistema de Alertas para Erros em Jobs e Workflows
# =============================================================================

# -----------------------------------------------------------------------------
# Notification Channel - E-mail
# -----------------------------------------------------------------------------
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "E-mail de Alertas - Erros Críticos"
  type         = "email"

  labels = {
    email_address = var.monitoring_alert_email
  }

  force_delete = false
}

# -----------------------------------------------------------------------------
# Alert Policy - Log-based para Cloud Run Jobs e Workflows
# -----------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "critical_errors" {
  project      = var.project_id
  display_name = "Erro Crítico - Jobs e Workflows"
  combiner     = "OR"
  enabled      = true

  documentation {
    content   = <<-EOT
      ## Alerta de Erro Crítico

      Um erro foi detectado em um Cloud Run Job ou Workflow.

      ### Ações Recomendadas:
      1. Acesse o Console do Google Cloud
      2. Navegue até **Logging > Logs Explorer**
      3. Filtre pelos logs com severity="ERROR"
      4. Identifique a causa raiz do erro
      5. Tome as medidas corretivas necessárias

      ### Links Úteis:
      - [Logs Explorer](https://console.cloud.google.com/logs/query?project=${var.project_id})
      - [Cloud Run Jobs](https://console.cloud.google.com/run/jobs?project=${var.project_id})
      - [Workflows](https://console.cloud.google.com/workflows?project=${var.project_id})
    EOT
    mime_type = "text/markdown"
  }

  # Condição A: Erros em Cloud Run Jobs
  conditions {
    display_name = "Erro em Cloud Run Job"

    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_run_job"
        severity="ERROR"
      EOT

      label_extractors = {
        "job_name"  = "EXTRACT(resource.labels.job_name)"
        "location"  = "EXTRACT(resource.labels.location)"
        "error_msg" = "EXTRACT(textPayload)"
      }
    }
  }

  # Condição B: Erros em Workflows
  conditions {
    display_name = "Erro em Workflow"

    condition_matched_log {
      filter = <<-EOT
        resource.type="workflows.googleapis.com/Workflow"
        severity="ERROR"
      EOT

      label_extractors = {
        "workflow_id" = "EXTRACT(resource.labels.workflow_id)"
        "location"    = "EXTRACT(resource.labels.location)"
        "error_msg"   = "EXTRACT(textPayload)"
      }
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s" # Limita notificações a no máximo 1 a cada 5 minutos
    }
    auto_close = "604800s" # Auto-fecha o incidente após 7 dias se não houver novos erros
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id
  ]

  user_labels = {
    environment = "production"
    team        = "data-engineering"
    severity    = "critical"
  }
}
