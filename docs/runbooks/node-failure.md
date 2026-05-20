# Runbook: GPU Node Failure

## Symptoms
- GPU node shows NotReady in kubectl get nodes
- Inference pods stuck in Pending
- DCGM metrics stop reporting

## Diagnosis
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl get pods -n inference -o wide

## Resolution
1. Wait 5-10 min for GKE auto-repair
2. Cordon and drain: kubectl cordon <node> && kubectl drain <node> --ignore-daemonsets
3. Resize node pool: gcloud container clusters resize nvidia-inference-cluster --node-pool gpu-pool --num-nodes 0 --zone us-central1-a, then scale back to 1
4. Check for Xid GPU hardware errors in nvidia-driver-daemonset logs

## Prevention
- Run multiple GPU nodes for redundancy
- Set PodDisruptionBudgets for minimum replicas
- Monitor node health with DCGM and alert on GPU errors
