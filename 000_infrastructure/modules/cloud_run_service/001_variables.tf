variable "name" {
  description = "The name of the Cloud Run service."
  type        = string
}

variable "location" {
  description = "The location for the Cloud Run service."
  type        = string
}

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "service_account_email" {
  description = "The email of the service account to be used by the Cloud Run service."
  type        = string
}

variable "container_image" {
  description = "The path to the container image in Artifact Registry."
  type        = string
}

variable "container_port" {
  description = "The port on which the container listens for requests."
  type        = number
  default     = 8080
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

variable "min_instances" {
  description = "The minimum number of instances to keep running."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "The maximum number of instances to scale to."
  type        = number
  default     = 10
}

variable "timeout_seconds" {
  description = "Max allowed time for an instance to respond to a request."
  type        = number
  default     = 300
}

variable "command" {
  description = "Entrypoint array. The docker image's ENTRYPOINT is used if this is not provided."
  type        = list(string)
  default     = null
}

variable "args" {
  description = "Arguments to the entrypoint. The docker image's CMD is used if this is not provided."
  type        = list(string)
  default     = null
}

variable "env_vars" {
  description = "A list of environment variables to set in the container."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "A list of secrets to mount as environment variables."
  type = list(object({
    name      = string
    secret_id = string
    version   = string
  }))
  default = []
}

variable "ingress" {
  description = "Ingress settings for the service. Valid values: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
}

variable "allow_unauthenticated" {
  description = "Whether to allow unauthenticated access to the service."
  type        = bool
  default     = false
}

variable "vpc_connector_name" {
  description = "The name of the VPC connector to use for egress traffic."
  type        = string
  default     = null
}

variable "vpc_egress" {
  description = "VPC egress settings. Valid values: ALL_TRAFFIC, PRIVATE_RANGES_ONLY"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
}

variable "labels" {
  description = "A map of labels to apply to the Cloud Run service."
  type        = map(string)
  default     = {}
}

variable "startup_probe" {
  description = "Startup probe configuration."
  type = object({
    enabled               = bool
    path                  = string
    initial_delay_seconds = number
    timeout_seconds       = number
    period_seconds        = number
    failure_threshold     = number
  })
  default = {
    enabled               = false
    path                  = "/"
    initial_delay_seconds = 0
    timeout_seconds       = 1
    period_seconds        = 10
    failure_threshold     = 3
  }
}

variable "liveness_probe" {
  description = "Liveness probe configuration."
  type = object({
    enabled               = bool
    path                  = string
    initial_delay_seconds = number
    timeout_seconds       = number
    period_seconds        = number
    failure_threshold     = number
  })
  default = {
    enabled               = false
    path                  = "/"
    initial_delay_seconds = 0
    timeout_seconds       = 1
    period_seconds        = 10
    failure_threshold     = 1
  }
}
