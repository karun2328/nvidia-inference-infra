variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}
variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west1" # Changes the region to Oregon
}
variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "nvidia-inference-cluster"
}

variable "gpu_node_count" {
  description = "Number of GPU nodes"
  type        = number
  default     = 1
}

variable "gpu_type" {
  description = "NVIDIA GPU type"
  type        = string
  default     = "nvidia-tesla-t4"
}
variable "gpu_count" {
  description = "Number of GPUs per node"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "GCE machine type for GPU nodes"
  type        = string
  default     = "n1-standard-4"
}
