output "service_id" {
  description = "The ID of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.id
}

output "service_name" {
  description = "The name of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.name
}

output "service_url" {
  description = "The URL of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.uri
}

output "service_latest_revision" {
  description = "The name of the latest revision of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.latest_ready_revision
}

output "service_location" {
  description = "The location of the Cloud Run service."
  value       = google_cloud_run_v2_service.default.location
}
