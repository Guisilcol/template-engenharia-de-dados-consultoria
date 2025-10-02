locals {
  artifact_image_path = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_registry_name}/${var.artifact_image_name_to_cloud_run}"
}
