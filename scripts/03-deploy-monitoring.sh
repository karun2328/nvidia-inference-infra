cat > scripts/03-deploy-monitoring.sh << 'EOF'
#!/bin/bash
set -e

echo "============================================"
echo "Step 3: Deploying Monitoring Stack"
echo "============================================"

# Prometheus + Grafana
echo "Installing kube-prometheus-stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# DCGM Exporter (NVIDIA GPU metrics)
echo ""
echo "Installing NVIDIA DCGM Exporter..."
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm install dcgm-exporter nvidia/dcgm-exporter \
  --namespace monitoring \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.additionalLabels.release=monitoring

echo ""
echo "Waiting for monitoring pods..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s

echo ""
echo "Monitoring stack status:"
kubectl get pods -n monitoring

echo ""
echo "============================================"
echo "Access Grafana:"
echo "  kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring"
echo "  Login: admin / prom-operator"
echo ""
echo "DCGM metrics available at:"
echo "  GPU utilization, memory, power, temperature, SM clock"
echo "============================================"
EOF
chmod +x scripts/03-deploy-monitoring.sh
