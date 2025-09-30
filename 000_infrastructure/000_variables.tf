variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região do GCP para deployment"
  type        = string
  default     = "us-central1"
}

variable "artifact_registry_name" {
  description = "O nome do Artifact Registry"
  type        = string
}

variable "artifact_image_name_to_cloud_run" {
  description = "O nome da imagem do Artifact Registry para Cloud Run Jobs"
  type        = string
}

variable "bronze_dataset_name" {
  description = "O nome do dataset da camada bronze"
  type        = string
}

variable "silver_dataset_name" {
  description = "O nome do dataset da camada silver"
  type        = string
}

variable "gold_dataset_name" {
  description = "O nome do dataset da camada gold"
  type        = string
}

variable "reception_bucket_name" {
  description = "O nome do bucket de recepção"
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

