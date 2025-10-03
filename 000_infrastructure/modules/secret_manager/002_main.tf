resource "google_secret_manager_secret" "secrets" {
  for_each = { for secret in var.secrets : secret.secret_id => secret }

  project   = var.project_id
  secret_id = each.value.secret_id

  labels = each.value.labels

  replication {
    auto {}
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret_version" "secret_versions" {
  for_each = google_secret_manager_secret.secrets

  secret      = each.value.id
  secret_data = var.secret_value

  lifecycle {
    ignore_changes = [secret_data]
  }
}
