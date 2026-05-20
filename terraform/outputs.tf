output "cluster_name" {
  value = google_container_cluster.inference_cluster.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.inference_cluster.endpoint
  sensitive = true
}

output "cluster_zone" {
  value = google_container_cluster.inference_cluster.location
}

output "kubectl_config_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.inference_cluster.name} --zone ${var.zone} --project ${var.project_id}"
}
