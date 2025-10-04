variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região do GCP para deployment"
  type        = string
}

variable "bronze_dataset_name" {
  description = "O nome do dataset da camada bronze"
  type        = string
  default     = "bronze"
}

variable "silver_dataset_name" {
  description = "O nome do dataset da camada silver"
  type        = string
  default     = "silver"
}

variable "gold_dataset_name" {
  description = "O nome do dataset da camada gold"
  type        = string
  default     = "gold"
}

variable "system_dataset_name" {
  description = "O nome do dataset de sistema (logs, metadados, etc)"
  type        = string
  default     = "system"
}

variable "reception_bucket_name" {
  description = "O nome do bucket da camada de recepção"
  type        = string
}

variable "bronze_bucket_name" {
  description = "O nome do bucket da camada bronze"
  type        = string
}

variable "silver_bucket_name" {
  description = "O nome do bucket da camada silver"
  type        = string
}

variable "gold_bucket_name" {
  description = "O nome do bucket da camada gold"
  type        = string
}
