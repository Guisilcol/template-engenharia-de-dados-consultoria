variable "name" {
  description = "The name of the Workflow."
  type        = string
}

variable "location" {
  description = "The location for the Workflow."
  type        = string
}

variable "project_id" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "service_account_email" {
  description = "The email of the service account to be used by the Workflow."
  type        = string
}

variable "workflow_yaml_path" {
  description = "The path to the YAML file containing the workflow definition."
  type        = string
}

variable "template_vars" {
  description = "A map of variables to be replaced in the workflow YAML template."
  type        = map(string)
  default     = {}
}

variable "description" {
  description = "Description of the workflow."
  type        = string
  default     = ""
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the workflow."
  type        = map(string)
  default     = {}
}
