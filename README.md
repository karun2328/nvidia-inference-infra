# NVIDIA GPU Inference Infrastructure on Kubernetes

Production-grade GPU inference platform using NVIDIA's stack: Triton Inference Server, GPU Operator, and DCGM monitoring on Kubernetes, with Terraform provisioning, Helm-based deployment, autoscaling, and canary rollouts.

## Architecture

Kubernetes Cluster (GKE)
├── CPU Node Pool (system workloads)
│   ├── Prometheus (metrics collection)
│   ├── Grafana (dashboards)
│   └── Alertmanager
└── GPU Node Pool (inference workloads)
    ├── NVIDIA GPU Operator (driver + device plugin + DCGM)
    ├── Triton Inference Server (model serving)
    └── DCGM Exporter (GPU telemetry)

## Tech Stack

- Infrastructure: Terraform (GKE provisioning), Kubernetes, Helm 3
- Serving: NVIDIA Triton Inference Server (OpenAI-compatible + gRPC)
- GPU Management: NVIDIA GPU Operator, DCGM Exporter
- Monitoring: Prometheus + Grafana + DCGM metrics
- Deployment: Canary rollouts with automated latency-based rollback

## Project Structure

nvidia-inference-infra/
├── terraform/                    # GKE cluster with GPU node pool
│   ├── main.tf                   # Cluster, CPU pool, GPU pool with T4
│   ├── variables.tf              # Configurable: GPU type, region, node count
│   └── outputs.tf
├── helm-charts/
│   └── triton-inference/         # Triton Helm chart
│       ├── values.yaml           # Model, GPU resources, autoscaling config
│       └── templates/            # Deployment, Service, ServiceMonitor, PVC
├── scripts/
│   ├── 01-create-cluster.sh      # Terraform apply + GPU operator install
│   ├── 02-deploy-triton.sh       # Helm install Triton
│   ├── 03-deploy-monitoring.sh   # Prometheus + DCGM + Grafana
│   ├── 04-benchmark.sh           # Load test with metrics capture
│   └── 05-canary-deploy.sh       # Canary rollout with auto-rollback
├── observability/
│   ├── dcgm-values.yaml          # DCGM exporter configuration
│   └── dashboards/               # Grafana dashboard configs
├── docs/runbooks/                # Operational runbooks
│   ├── gpu-oom.md
│   ├── node-failure.md
│   └── model-loading-timeout.md
└── results/
    └── benchmark_results.md

## Key Design Decisions

### Separate Node Pools
CPU workloads (Prometheus, Grafana) run on cheap e2-standard-2 nodes. GPU workloads run on n1-standard-4 + T4 nodes with taints to prevent non-GPU pods from scheduling on expensive hardware.

### NVIDIA GPU Operator
Manages the full NVIDIA software stack on K8s: GPU drivers, container runtime, device plugin, and DCGM. Eliminates manual driver installation and ensures consistent GPU support across nodes.

### DCGM Monitoring
Goes beyond basic nvidia-smi metrics. DCGM exposes SM utilization, memory bandwidth, PCIe throughput, power draw, thermal throttling, and ECC errors — the metrics NVIDIA's own teams use to monitor GPU clusters.

### Triton Inference Server
NVIDIA's production inference server supporting multiple backends (TensorRT, PyTorch, ONNX, TensorRT-LLM). Exposes Prometheus metrics natively, supports dynamic batching, model versioning, and ensemble pipelines.

### Canary Deployments
New model versions deploy alongside stable versions. The canary script monitors Triton's inference latency metrics and auto-rolls back if canary latency exceeds 2x the stable baseline.

## Helm Chart Usage

# Deploy with defaults (Triton on 1x T4 GPU)
helm install triton helm-charts/triton-inference/ --namespace inference --create-namespace

# Deploy with custom model and 2 GPUs
helm install triton helm-charts/triton-inference/ \
  --namespace inference \
  --set resources.limits."nvidia\.com/gpu"=2 \
  --set model.name="llama-trtllm"

# Canary deploy a new Triton version
bash scripts/05-canary-deploy.sh 20 24.09-trtllm-python-py3

## Monitoring

### DCGM GPU Metrics (via Prometheus)
- DCGM_FI_DEV_GPU_UTIL: GPU SM utilization %
- DCGM_FI_DEV_FB_USED: GPU memory used (MiB)
- DCGM_FI_DEV_POWER_USAGE: Power draw (W)
- DCGM_FI_DEV_GPU_TEMP: GPU temperature
- DCGM_FI_DEV_PCIE_TX/RX_THROUGHPUT: PCIe bandwidth

### Triton Inference Metrics
- nv_inference_request_duration_us: Request latency histogram
- nv_inference_queue_duration_us: Queue wait time
- nv_inference_request_success: Successful inference count
- nv_inference_request_failure: Failed inference count
- nv_gpu_utilization: GPU utilization per model

## Deployment

### Prerequisites
- GCP account with billing enabled
- gcloud CLI installed and authenticated
- Terraform >= 1.0
- kubectl and Helm 3

### Quick Start
# 1. Provision GKE cluster with GPU nodes
cd terraform && terraform init && terraform apply

# 2. Configure kubectl
gcloud container clusters get-credentials nvidia-inference-cluster --zone us-central1-a

# 3. Install GPU Operator + monitoring + Triton
bash scripts/01-create-cluster.sh
bash scripts/03-deploy-monitoring.sh
bash scripts/02-deploy-triton.sh

# 4. Run benchmarks
bash scripts/04-benchmark.sh
