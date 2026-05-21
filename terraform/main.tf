terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
provider "google" {
  project = var.project_id
  region  = var.region
}
resource "google_container_cluster" "inference_cluster" {
  name                     = var.cluster_name
  location                 = var.zone
  remove_default_node_pool = true
  initial_node_count       = 1
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {}
  release_channel {
    channel = "REGULAR"
  }
}
resource "google_container_node_pool" "cpu_pool" {
  name       = "cpu-pool"
  location   = var.zone
  cluster    = google_container_cluster.inference_cluster.name
  node_count = 1
  node_config {
    machine_type = "e2-standard-2"
    disk_size_gb = 50
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    labels = { role = "system" }
  }
}
resource "google_container_node_pool" "gpu_pool" {
  name       = "gpu-pool"
  location   = var.zone
  cluster    = google_container_cluster.inference_cluster.name
  node_count = var.gpu_node_count
  node_config {
    machine_type = var.machine_type
    disk_size_gb = 100
    guest_accelerator {
      type  = var.gpu_type
      count = var.gpu_count
      gpu_driver_installation_config {
        gpu_driver_version = "LATEST"
      }
    }
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    labels = { role = "inference" }
    taint {
      key    = "nvidia.com/gpu"
      value  = "present"
      effect = "NO_SCHEDULE"
    }
  }
}
