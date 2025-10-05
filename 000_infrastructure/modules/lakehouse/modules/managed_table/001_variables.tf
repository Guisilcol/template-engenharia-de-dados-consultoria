variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "dataset_id" {
  description = "ID do dataset do BigQuery"
  type        = string
}

variable "table_id" {
  description = "ID da tabela no BigQuery"
  type        = string
}

variable "schema" {
  description = "Schema da tabela em formato JSON"
  type        = string
}

variable "deletion_protection" {
  description = "Proteção contra deleção da tabela"
  type        = bool
  default     = false
}

variable "description" {
  description = "Descrição da tabela"
  type        = string
  default     = null
}

variable "time_partitioning" {
  description = "Configuração de particionamento por tempo"
  type = object({
    type                     = string
    field                    = optional(string)
    expiration_ms            = optional(number)
    require_partition_filter = optional(bool)
  })
  default = null
}

variable "clustering" {
  description = "Lista de campos para clustering"
  type        = list(string)
  default     = null
}

variable "labels" {
  description = "Labels para a tabela"
  type        = map(string)
  default     = {}
}

variable "expiration_time" {
  description = "Tempo de expiração da tabela em milissegundos desde epoch"
  type        = number
  default     = null
}
