output "table_id" {
  description = "ID da tabela externa criada"
  value       = google_bigquery_table.external_table.table_id
}

output "table_reference" {
  description = "Referência completa da tabela (project.dataset.table)"
  value       = "${var.project_id}.${var.dataset_id}.${google_bigquery_table.external_table.table_id}"
}

output "self_link" {
  description = "Self link da tabela"
  value       = google_bigquery_table.external_table.self_link
}
