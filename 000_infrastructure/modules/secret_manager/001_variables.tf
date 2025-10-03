variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "secrets" {
  description = "Lista de secrets a serem criados"
  type = list(object({
    secret_id   = string
    description = optional(string, "Secret gerenciado pelo Terraform")
    labels      = optional(map(string), {})
  }))
  default = []
}

variable "secret_value" {
  description = "Valor padrão para os secrets (string vazia)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "replication_policy" {
  description = "Política de replicação do secret (automatic ou user_managed)"
  type        = string
  default     = "automatic"
}
