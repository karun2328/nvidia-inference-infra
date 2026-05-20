cat > scripts/04-benchmark.sh << 'EOF'
#!/bin/bash
MODEL="${1:-ensemble}"
NUM_REQUESTS="${2:-20}"
ENDPOINT="${3:-http://localhost:8000}"

echo "============================================"
echo "Triton Inference Benchmark"
echo "============================================"
echo "Model:    $MODEL"
echo "Requests: $NUM_REQUESTS (concurrent)"
echo "Endpoint: $ENDPOINT"
echo "============================================"

# Health check
curl -s "${ENDPOINT}/v2/health/ready" > /dev/null || { echo "ERROR: Triton not responding"; exit 1; }

echo ""
echo "Starting benchmark..."
START_TIME=$(date +%s%N)

for i in $(seq 1 $NUM_REQUESTS); do
  curl -s -X POST "${ENDPOINT}/v2/models/${MODEL}/infer" \
    -H "Content-Type: application/json" \
    -d '{
      "inputs": [{
        "name": "text_input",
        "shape": [1],
        "datatype": "BYTES",
        "data": ["Explain concept number '$i' in machine learning briefly"]
      }],
      "parameters": {"max_tokens": 150}
    }' > /dev/null &
done
wait

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo "Benchmark complete! Duration: ${DURATION}ms"

echo ""
echo "============================================"
echo "Triton Metrics"
echo "============================================"
curl -s "${ENDPOINT}:8002/metrics" | grep -E "nv_inference_request_success|nv_inference_queue_duration|nv_inference_compute_infer_duration|nv_gpu_utilization|nv_gpu_memory_used"

echo ""
echo "GPU Status:"
nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu,temperature.gpu,power.draw --format=csv
EOF
chmod +x scripts/04-benchmark.sh
