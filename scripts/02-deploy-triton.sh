cat > scripts/02-deploy-triton.sh << 'EOF'
#!/bin/bash
set -e

echo "============================================"
echo "Step 2: Deploying Triton Inference Server"
echo "============================================"

# Deploy Triton via Helm chart
helm install triton helm-charts/triton-inference/ \
  --namespace inference \
  --create-namespace

echo ""
echo "Waiting for Triton pod to be ready (model loading may take a few minutes)..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=triton-inference \
  -n inference --timeout=600s

echo ""
echo "Triton status:"
kubectl get pods -n inference
kubectl get svc -n inference

echo ""
echo "Testing Triton health..."
kubectl port-forward svc/triton-triton-inference 8000:8000 -n inference &
sleep 3
curl -s localhost:8000/v2/health/ready && echo " - Triton is ready!"
kill %1 2>/dev/null

echo "============================================"
echo "Triton deployed successfully!"
echo "============================================"
EOF
chmod +x scripts/02-deploy-triton.sh
