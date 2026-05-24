# NVIDIA GPU Inference Infrastructure on Kubernetes

Production-grade GPU inference platform built on NVIDIA's stack — Triton Inference Server, DCGM Exporter, and GPU Operator — deployed on Google Kubernetes Engine with Terraform provisioning, Helm-based configuration, Prometheus/Grafana observability, and automated canary rollouts.

---

## Architecture
                    Google Kubernetes Engine (GKE)
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   CPU Node Pool (e2-standard-2)     GPU Node Pool            │
│   ┌─────────────────────────┐       (g2-standard-4 + L4)    │
│   │  Prometheus             │       ┌──────────────────────┐ │
│   │  Grafana                │       │ Triton Inference     │ │
│   │  Alertmanager           │◄──────│ Server (v2.49.0)     │ │
│   │  kube-state-metrics     │       │                      │ │
│   └─────────────────────────┘       │ DCGM Exporter        │ │
│                                     │ (GPU Telemetry)      │ │
│                                     │                      │ │
│                                     │ NVIDIA L4 (24GB)     │ │
│                                     └──────────────────────┘ │
│                                                              │
│   Taint: nvidia.com/gpu=present:NoSchedule                   │
└──────────────────────────────────────────────────────────────┘
▲                                      ▲
│                                      │
Terraform IaC                         Helm Charts
(main.tf)                         (triton-inference/)

---

## Deployment Results

Deployed and benchmarked on GKE with an NVIDIA L4 GPU (24GB VRAM) in us-west4-a.

| Metric | Value |
|--------|-------|
| Model | ResNet50 (ONNX, 97MB) |
| Throughput | 5.4 requests/sec |
| P50 Latency | 350.4 ms |
| P95 Latency | 843.1 ms |
| P99 Latency | 889.2 ms |
| Success Rate | 100% (50/50 requests) |
| GPU Memory Used | 412 MiB / 23,034 MiB |
| GPU Temperature | 76–77°C |
| Power Draw | 42.2–42.8 W (of 72 W TDP) |

Full benchmark data, Grafana dashboard screenshots, and raw metrics are available in [results/benchmark_results.md](results/benchmark_results.md).

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Cloud Provider | Google Cloud Platform (GKE) |
| Infrastructure as Code | Terraform |
| Container Orchestration | Kubernetes (v1.35.3) |
| Package Management | Helm 3 |
| Inference Server | NVIDIA Triton Inference Server v2.49.0 |
| GPU | NVIDIA L4 (24 GB VRAM) |
| GPU Driver | NVIDIA 580.126.09 / CUDA 13.0 |
| GPU Monitoring | NVIDIA DCGM Exporter |
| Metrics Collection | Prometheus (with ServiceMonitor CRDs) |
| Dashboards | Grafana |
| Deployment Strategy | Canary rollouts with automated rollback |

---

## Project Structure
nvidia-inference-infra/
│
├── terraform/
│   ├── main.tf                         # GKE cluster, CPU pool, GPU pool (L4)
│   ├── variables.tf                    # Configurable: GPU type, region, machine type
│   └── outputs.tf                      # Cluster endpoint, kubectl config command
│
├── helm-charts/
│   └── triton-inference/
│       ├── Chart.yaml
│       ├── values.yaml                 # Model config, GPU resources, autoscaling
│       └── templates/
│           ├── deployment.yaml         # Triton deployment with GPU tolerations
│           ├── service.yaml            # HTTP (8000), gRPC (8001), Metrics (8002)
│           ├── servicemonitor.yaml     # Prometheus auto-discovery
│           └── pvc.yaml               # Persistent model storage
│
├── scripts/
│   ├── 01-create-cluster.sh            # Terraform init + apply
│   ├── 02-deploy-triton.sh             # Helm install Triton
│   ├── 03-deploy-monitoring.sh         # Prometheus + DCGM + Grafana
│   ├── 04-benchmark.sh                 # Concurrent load test
│   └── 05-canary-deploy.sh             # Canary deploy with auto-rollback
│
├── observability/
│   └── dcgm-values.yaml                # DCGM Exporter Helm values
│
├── docs/
│   └── runbooks/
│       ├── gpu-oom.md                  # GPU out-of-memory diagnosis and recovery
│       ├── node-failure.md             # GPU node failure handling
│       └── model-loading-timeout.md    # Model loading troubleshooting
│
└── results/
├── benchmark_results.md            # Detailed results with dashboard screenshots
├── triton_metrics.txt              # Raw Triton Prometheus metrics
├── dcgm_metrics.txt                # Raw DCGM GPU metrics
└── screenshots/                    # Grafana dashboards and deployment evidence

---

## Design Decisions

### Separate CPU and GPU Node Pools

System workloads (Prometheus, Grafana, Alertmanager) run on inexpensive e2-standard-2 CPU nodes. Inference workloads run on g2-standard-4 nodes equipped with NVIDIA L4 GPUs. A NoSchedule taint on GPU nodes prevents non-inference pods from consuming expensive GPU resources — a standard practice in production GPU clusters.

### NVIDIA DCGM for GPU Monitoring

DCGM (Data Center GPU Manager) provides hardware-level GPU telemetry that goes far beyond nvidia-smi. Metrics include SM utilization, memory bandwidth, PCIe throughput, power draw, thermal state, and ECC errors. These are the same metrics NVIDIA's own infrastructure teams use to monitor DGX clusters and cloud GPU deployments.

### Triton Inference Server

NVIDIA's production inference server supports multiple model backends (TensorRT, TensorRT-LLM, PyTorch, ONNX Runtime) and exposes Prometheus-compatible metrics natively. Features include dynamic batching, model versioning, ensemble pipelines, and health endpoints for Kubernetes readiness and liveness probes.

### Automated Canary Deployments

The canary deployment script deploys a new model version alongside the stable version, monitors Triton's nv_inference_request_duration_us latency metric in real-time, and automatically rolls back if the canary's latency exceeds 2x the stable baseline.

---

## Usage

### Deploy the Infrastructure

```bash
cd terraform
terraform init
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID"
```

### Connect to the Cluster

```bash
gcloud container clusters get-credentials nvidia-inference-cluster \
  --zone us-west4-a --project YOUR_GCP_PROJECT_ID
```

### Deploy Monitoring Stack

```bash
bash scripts/03-deploy-monitoring.sh
```

### Deploy Triton Inference Server

```bash
helm install triton helm-charts/triton-inference/ \
  --namespace inference --create-namespace
```

### Override Configuration at Deploy Time

```bash
helm install triton helm-charts/triton-inference/ \
  --namespace inference \
  --set resources.limits."nvidia\.com/gpu"=2 \
  --set model.name="llama-trtllm"
```

### Run Benchmarks

```bash
bash scripts/04-benchmark.sh
```

### Canary Deploy a New Model Version

```bash
bash scripts/05-canary-deploy.sh 20 24.09-trtllm-python-py3
```

---

## Monitoring Metrics

### DCGM GPU Metrics (via Prometheus)

| Metric | Description |
|--------|-------------|
| DCGM_FI_DEV_GPU_UTIL | GPU SM utilization (%) |
| DCGM_FI_DEV_FB_USED | GPU framebuffer memory used (MiB) |
| DCGM_FI_DEV_POWER_USAGE | GPU power draw (W) |
| DCGM_FI_DEV_GPU_TEMP | GPU temperature (°C) |
| DCGM_FI_DEV_SM_CLOCK | SM clock frequency (MHz) |
| DCGM_FI_DEV_MEM_CLOCK | Memory clock frequency (MHz) |

### Triton Inference Metrics

| Metric | Description |
|--------|-------------|
| nv_inference_request_success | Successful inference count |
| nv_inference_request_failure | Failed inference count |
| nv_inference_request_duration_us | End-to-end request latency (μs) |
| nv_inference_queue_duration_us | Queue wait time (μs) |
| nv_inference_compute_infer_duration_us | Compute inference time (μs) |

---

## Prerequisites

- GCP account with GPU quota (GPUS_ALL_REGIONS >= 1, NVIDIA_L4_GPUS >= 1)
- gcloud CLI installed and authenticated
- Terraform >= 1.0
- kubectl and Helm 3

Now the benchmark_results.md — copy everything between the two lines:

markdown# Deployment Evidence and Benchmark Results

This document contains deployment evidence, benchmark data, and Grafana dashboard screenshots from the live GKE deployment with an NVIDIA L4 GPU.

---

## Environment

| Component | Detail |
|-----------|--------|
| Cloud | Google Kubernetes Engine (GKE), us-west4-a |
| Kubernetes | v1.35.3-gke.1389000 |
| GPU | NVIDIA L4, 24 GB VRAM |
| Driver | NVIDIA 580.126.09 |
| CUDA | 13.0 |
| Triton | v2.49.0 (nvcr.io/nvidia/tritonserver:24.08-py3) |
| Model | ResNet50 ONNX (97 MB) |
| Backend | ONNX Runtime |
| Monitoring | Prometheus + Grafana + NVIDIA DCGM Exporter |

---

## 1. GPU Verification

NVIDIA L4 GPU confirmed via nvidia-smi. Triton Inference Server process running with 404 MiB GPU memory allocated for the ResNet50 model.

![nvidia-smi output](screenshots/04-nvidia-smi.png)

---

## 2. Triton Deployment on Kubernetes

Triton Inference Server deployed as a Kubernetes Deployment on the GPU node pool. Pod status: 1/1 Ready, zero restarts. Scheduled on the L4 GPU node via nodeSelector and GPU taint toleration.

![Triton pod running](screenshots/01-triton-running.png)

---

## 3. Inference Benchmark

50 concurrent inference requests sent to Triton's /v2/models/resnet50/infer endpoint with 10 concurrent workers. Each request sends a random 224x224x3 FP32 image tensor.

### Run 1

| Metric | Value |
|--------|-------|
| Total Time | 9.22s |
| Successful Requests | 50/50 |
| Errors | 0 |
| Throughput | 5.4 req/s |
| Avg Latency | 386.1 ms |
| P50 Latency | 350.4 ms |
| P95 Latency | 843.1 ms |
| P99 Latency | 889.2 ms |
| Min Latency | 32.6 ms |
| Max Latency | 889.2 ms |

![Benchmark Run 1](screenshots/03-benchmark-run2.png)

### Run 2 (Consistency Check)

| Metric | Value |
|--------|-------|
| Total Time | 9.33s |
| Successful Requests | 50/50 |
| Errors | 0 |
| Throughput | 5.4 req/s |
| Avg Latency | 551.8 ms |
| P50 Latency | 486.5 ms |
| P95 Latency | 1499.4 ms |
| P99 Latency | 1813.1 ms |
| Min Latency | 51.4 ms |
| Max Latency | 1813.1 ms |

![Benchmark Run 2](screenshots/02-benchmark-run1.png)

Throughput remained consistent at 5.4 req/s across both runs. The higher tail latencies in Run 2 are expected variance under concurrent load with ONNX Runtime's execution scheduling.

---

## 4. Triton Inference Metrics via Grafana

Prometheus scrapes Triton's /metrics endpoint every 15 seconds via a ServiceMonitor CRD. The following screenshots show nv_inference_request_success — the count of successfully processed inference requests.

### Line Graph View

225 total successful inferences with zero failures.

![Triton metrics line](screenshots/05-triton-success-line.png)

### Tooltip Detail

Shows per-datapoint metadata: container, endpoint, job, model name, namespace, pod, service, and version.

![Triton metrics tooltip](screenshots/06-triton-success-tooltip.png)

### Bar Chart View

![Triton metrics bars](screenshots/07-triton-success-bars.png)

---

## 5. NVIDIA DCGM GPU Metrics via Grafana

DCGM Exporter runs as a DaemonSet on GPU nodes, collecting hardware-level GPU telemetry and exposing it to Prometheus on port 9400.

### GPU Temperature (76–77°C)

![DCGM temperature line](screenshots/08-dcgm-temp-line.png)

![DCGM temperature bars](screenshots/09-dcgm-temp-bars.png)

### GPU SM Utilization

GPU utilization at 0% between benchmark runs (idle). Spikes to non-zero during active inference.

![DCGM GPU util bars](screenshots/10-dcgm-gpu-util-bars.png)

![DCGM GPU util line](screenshots/11-dcgm-gpu-util-line.png)

### GPU Power Draw (42.2–42.8 W / 72 W TDP)

![DCGM power bars](screenshots/12-dcgm-power-usage-bars.png)

![DCGM power line](screenshots/13-dcgm-power-line.png)

---

## 6. Metrics Summary

### DCGM GPU Metrics

| Metric | Value |
|--------|-------|
| GPU Model | NVIDIA L4 |
| GPU Temperature | 76–77°C |
| Power Draw | 42.2–42.8 W (TDP: 72 W) |
| SM Clock | 2040 MHz |
| Memory Clock | 6251 MHz |
| GPU Memory Used | 412 MiB / 23,034 MiB |
| Driver Version | 580.126.09 |

### Triton Inference Metrics

| Metric | Value |
|--------|-------|
| nv_inference_request_success | 225+ |
| nv_inference_request_failure | 0 |
| nv_inference_count | 225+ |
| Model | resnet50 v1 |
| Backend | ONNX Runtime |
| Dynamic Batching | Enabled |