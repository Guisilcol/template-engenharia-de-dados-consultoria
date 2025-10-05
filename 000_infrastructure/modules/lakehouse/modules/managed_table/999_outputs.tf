output "table_id" {
  description = "ID da tabela gerenciada criada"
  value       = google_bigquery_table.managed_table.table_id
}

output "table_reference" {
  description = "Referência completa da tabela (project.dataset.table)"
  value       = "${var.project_id}.${var.dataset_id}.${google_bigquery_table.managed_table.table_id}"
}

output "self_link" {
  description = "Self link da tabela"
  value       = google_bigquery_table.managed_table.self_link
}

output "creation_time" {
  description = "Timestamp de criação da tabela"
  value       = google_bigquery_table.managed_table.creation_time
}

output "num_bytes" {
  description = "Tamanho da tabela em bytes"
  value       = google_bigquery_table.managed_table.num_bytes
}

output "num_rows" {
  description = "Número de linhas na tabela"
  value       = google_bigquery_table.managed_table.num_rows
}
