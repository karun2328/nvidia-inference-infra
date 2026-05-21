variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west4"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-west4-a"
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
  default     = "nvidia-l4"
}

variable "gpu_count" {
  description = "Number of GPUs per node"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "GCE machine type for GPU nodes"
  type        = string
  default     = "g2-standard-4"
}
