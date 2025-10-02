variable "name" {
  description = "The name of the Cloud Run job."
  type        = string
}

variable "location" {
  description = "The location for the Cloud Run job."
  type        = string
}

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "service_account_email" {
  description = "The email of the service account to be used by the Cloud Run job."
  type        = string
}

variable "artifact_image_path" {
  description = "The path to the container image in Artifact Registry."
  type        = string
}

variable "args" {
  description = "Arguments to the container."
  type        = list(string)
  default     = []
}

variable "cpu_limit" {
  description = "The CPU limit for the container."
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "The memory limit for the container."
  type        = string
  default     = "512Mi"
}
