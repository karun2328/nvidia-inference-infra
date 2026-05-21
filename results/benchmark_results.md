# Triton Inference Server Benchmark Results

## Environment
- GPU: NVIDIA L4 (24GB VRAM)
- Platform: GKE (Google Kubernetes Engine), us-west4-a
- Kubernetes: v1.35.3
- Triton Server: v2.49.0 (24.08-py3)
- Model: ResNet50 ONNX (97MB)
- Backend: ONNX Runtime

## Benchmark: 50 Requests, 10 Concurrent
| Metric | Value |
|--------|-------|
| Total Time | 9.22s |
| Successful | 50/50 |
| Errors | 0 |
| Throughput | 5.4 req/s |
| Avg Latency | 386.1ms |
| P50 Latency | 350.4ms |
| P95 Latency | 843.1ms |
| P99 Latency | 889.2ms |
| Min Latency | 32.6ms |
| Max Latency | 889.2ms |

## GPU Metrics (DCGM)
- GPU Temperature: 76-77C
- Power Draw: 42.2-42.8W
- SM Clock: 2040 MHz
- Memory Clock: 6251 MHz
- Driver: 580.126.09

## Triton Metrics
- nv_inference_request_success: 225+
- nv_inference_request_failure: 0
- Model: resnet50 v1, ONNX Runtime backend
