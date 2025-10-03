output "secret_ids" {
  description = "IDs dos secrets criados"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.id }
}

output "secret_names" {
  description = "Nomes dos secrets criados"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.name }
}

output "secret_version_ids" {
  description = "IDs das versões dos secrets"
  value       = { for k, v in google_secret_manager_secret_version.secret_versions : k => v.id }
}
