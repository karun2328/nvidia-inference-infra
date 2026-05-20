cat > scripts/01-create-cluster.sh << 'EOF'
#!/bin/bash
set -e

PROJECT_ID="${1:?Usage: $0 <project-id>}"
ZONE="us-central1-a"
CLUSTER_NAME="nvidia-inference-cluster"

echo "============================================"
echo "Step 1: Provisioning GKE Cluster"
echo "============================================"

cd terraform
terraform init
terraform apply -auto-approve \
  -var="project_id=${PROJECT_ID}" \
  -var="zone=${ZONE}"

echo ""
echo "Configuring kubectl..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

echo ""
echo "Installing NVIDIA GPU Operator..."
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --set driver.enabled=false \
  --set toolkit.enabled=true

echo ""
echo "Waiting for GPU operator pods..."
kubectl wait --for=condition=ready pod -l app=nvidia-device-plugin-daemonset -n gpu-operator --timeout=300s

echo ""
echo "Verifying GPU visibility..."
kubectl get nodes -o json | jq '.items[].status.allocatable["nvidia.com/gpu"]'

echo "============================================"
echo "Cluster ready with GPU support!"
echo "============================================"
EOF
chmod +x scripts/01-create-cluster.sh
