variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "Região do GCP para deployment"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona do GCP para deployment"
  type        = string
  default     = "us-central1-a"
  
}
