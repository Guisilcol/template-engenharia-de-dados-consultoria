output "bronze_dataset_id" {
  description = "The ID of the bronze dataset"
  value       = google_bigquery_dataset.bronze_dataset.dataset_id
}

output "silver_dataset_id" {
  description = "The ID of the silver dataset"
  value       = google_bigquery_dataset.silver_dataset.dataset_id
}

output "gold_dataset_id" {
  description = "The ID of the gold dataset"
  value       = google_bigquery_dataset.gold_dataset.dataset_id
}

output "system_dataset_id" {
  description = "The ID of the system dataset"
  value       = google_bigquery_dataset.system_dataset.dataset_id
}
