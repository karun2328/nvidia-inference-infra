# Runbook: Model Loading Timeout

## Symptoms
- Triton pod Running but 0/1 Ready
- Readiness probe failed: HTTP 503
- Model loading not completing

## Diagnosis
kubectl get pods -n inference -o wide
kubectl logs -n inference deploy/triton-triton-inference --tail=200
kubectl exec -n inference deploy/triton-triton-inference -- ls -la /models/
kubectl exec -n inference deploy/triton-triton-inference -- nvidia-smi

## Resolution
1. Increase readiness probe timeout (initialDelaySeconds=300)
2. Verify model repository structure: /models/<name>/config.pbtxt + /models/<name>/1/model.plan
3. Ensure TensorRT engine matches GPU architecture (T4=SM75, A100=SM80)
4. Check PVC storage: kubectl get pvc -n inference

## Prevention
- Pre-validate model loading on test instance
- Set appropriate probe timeouts based on model size
- Use Triton model warmup to verify loading
