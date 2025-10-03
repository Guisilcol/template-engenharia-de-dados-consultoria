variable "name" {
  description = "Nome do Cloud Scheduler job"
  type        = string
}

variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região do Cloud Scheduler"
  type        = string
}

variable "description" {
  description = "Descrição do scheduler job"
  type        = string
  default     = "Trigger gerenciado pelo Terraform"
}

variable "schedule" {
  description = "Expressão cron para agendamento (ex: '0 9 * * *' para todo dia às 9h)"
  type        = string
}

variable "time_zone" {
  description = "Fuso horário para o agendamento"
  type        = string
  default     = "America/Sao_Paulo"
}

variable "paused" {
  description = "Se o scheduler deve estar pausado"
  type        = bool
  default     = false
}

variable "target_type" {
  description = "Tipo de alvo: 'workflow' ou 'cloud_run_job'"
  type        = string
  validation {
    condition     = contains(["workflow", "cloud_run_job"], var.target_type)
    error_message = "target_type deve ser 'workflow' ou 'cloud_run_job'"
  }
}

# Variáveis para Workflow
variable "workflow_name" {
  description = "Nome do Workflow a ser executado (obrigatório se target_type = 'workflow')"
  type        = string
  default     = null
}

variable "workflow_location" {
  description = "Localização do Workflow"
  type        = string
  default     = null
}

variable "workflow_argument" {
  description = "Argumentos JSON para o Workflow"
  type        = string
  default     = "{}"
}

# Variáveis para Cloud Run Job
variable "cloud_run_job_name" {
  description = "Nome do Cloud Run Job a ser executado (obrigatório se target_type = 'cloud_run_job')"
  type        = string
  default     = null
}

variable "cloud_run_job_location" {
  description = "Localização do Cloud Run Job"
  type        = string
  default     = null
}

# Service Account
variable "service_account_email" {
  description = "Email da service account para executar o trigger"
  type        = string
}

variable "attempt_deadline" {
  description = "Tempo máximo de tentativa (ex: '320s')"
  type        = string
  default     = "320s"
}

variable "retry_config" {
  description = "Configuração de retry"
  type = object({
    retry_count          = optional(number, 0)
    max_retry_duration   = optional(string, "0s")
    min_backoff_duration = optional(string, "5s")
    max_backoff_duration = optional(string, "3600s")
    max_doublings        = optional(number, 5)
  })
  default = {
    retry_count = 0
  }
}
