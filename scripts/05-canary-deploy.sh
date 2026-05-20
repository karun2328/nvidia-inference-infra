#!/bin/bash
set -e

CANARY_WEIGHT="${1:-20}"
CANARY_TAG="${2:-24.09-trtllm-python-py3}"
NAMESPACE="inference"
RELEASE_NAME="triton"

echo "============================================"
echo "Canary Deployment"
echo "============================================"
echo "Canary Weight:  ${CANARY_WEIGHT}%"
echo "Canary Image:   nvcr.io/nvidia/tritonserver:${CANARY_TAG}"
echo "============================================"

# Deploy canary alongside stable
helm upgrade ${RELEASE_NAME} helm-charts/triton-inference/ \
  --namespace ${NAMESPACE} \
  --set canary.enabled=true \
  --set canary.weight=${CANARY_WEIGHT} \
  --set canary.canaryTag=${CANARY_TAG} \
  --reuse-values

echo ""
echo "Canary deployed. Monitoring for 5 minutes..."
echo ""

# Monitor canary vs stable metrics
for i in $(seq 1 30); do
  sleep 10

  STABLE_LATENCY=$(kubectl exec -n ${NAMESPACE} deploy/${RELEASE_NAME}-triton-inference -- \
    curl -s localhost:8002/metrics 2>/dev/null | \
    grep 'nv_inference_request_duration_us_sum' | \
    awk '{print $2}' || echo "N/A")

  CANARY_LATENCY=$(kubectl exec -n ${NAMESPACE} deploy/${RELEASE_NAME}-canary-triton-inference -- \
    curl -s localhost:8002/metrics 2>/dev/null | \
    grep 'nv_inference_request_duration_us_sum' | \
    awk '{print $2}' || echo "N/A")

  echo "[$(date +%H:%M:%S)] Stable latency: ${STABLE_LATENCY}us | Canary latency: ${CANARY_LATENCY}us"

  # Auto-rollback if canary latency is 2x worse
  if [[ "$STABLE_LATENCY" != "N/A" && "$CANARY_LATENCY" != "N/A" ]]; then
    if (( $(echo "$CANARY_LATENCY > $STABLE_LATENCY * 2" | bc -l 2>/dev/null) )); then
      echo ""
      echo "ALERT: Canary latency ${CANARY_LATENCY}us > 2x stable ${STABLE_LATENCY}us"
      echo "Rolling back canary..."
      helm upgrade ${RELEASE_NAME} helm-charts/triton-inference/ \
        --namespace ${NAMESPACE} \
        --set canary.enabled=false \
        --reuse-values
      echo "Rollback complete."
      exit 1
    fi
  fi
done

echo ""
echo "Canary monitoring passed."
read -p "Promote canary to stable? (y/n): " PROMOTE

if [[ "$PROMOTE" == "y" ]]; then
  helm upgrade ${RELEASE_NAME} helm-charts/triton-inference/ \
    --namespace ${NAMESPACE} \
    --set image.tag=${CANARY_TAG} \
    --set canary.enabled=false \
    --reuse-values
  echo "Canary promoted to stable."
else
  helm upgrade ${RELEASE_NAME} helm-charts/triton-inference/ \
    --namespace ${NAMESPACE} \
    --set canary.enabled=false \
    --reuse-values
  echo "Canary rolled back."
fi
