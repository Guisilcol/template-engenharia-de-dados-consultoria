# Artifact Registry para armazenar as imagens Docker
resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "docker-repo"
  description   = "Repositório Docker."
  format        = "DOCKER"

  depends_on = [google_project_service.required_apis]
}