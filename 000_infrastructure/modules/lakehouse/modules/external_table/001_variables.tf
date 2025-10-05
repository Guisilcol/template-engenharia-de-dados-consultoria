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

variable "bucket_name" {
  description = "Nome do bucket GCS"
  type        = string
}

variable "table_prefix" {
  description = "Prefixo do caminho da tabela no GCS (ex: tb_external_sample)"
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

variable "source_format" {
  description = "Formato dos arquivos fonte (PARQUET, CSV, etc)"
  type        = string
  default     = "PARQUET"
}

variable "autodetect" {
  description = "Auto-detectar schema"
  type        = bool
  default     = false
}

variable "hive_partitioning_mode" {
  description = "Modo de particionamento Hive (STRINGS, AUTO, CUSTOM)"
  type        = string
  default     = "STRINGS"
}

variable "require_partition_filter" {
  description = "Requer filtro de partição nas queries"
  type        = bool
  default     = false
}

variable "create_dummy_file" {
  description = "Criar arquivo dummy para inicializar a tabela externa"
  type        = bool
  default     = true
}

variable "dummy_partition_name" {
  description = "Nome da partição dummy"
  type        = string
  default     = "partition=dummy"
}
