# Runbook: GPU Out of Memory (OOM)

## Symptoms
- Triton pod in CrashLoopBackOff or OOMKilled status
- nvidia-smi shows GPU memory at 100%
- Triton logs: CUDA out of memory

## Diagnosis
kubectl describe pod -l app.kubernetes.io/name=triton-inference -n inference
kubectl logs -l app.kubernetes.io/name=triton-inference -n inference --tail=100
kubectl exec -n inference deploy/triton-triton-inference -- nvidia-smi

## Resolution
1. Reduce model memory: switch to quantized model (INT8/INT4)
2. Reduce max batch size in model config.pbtxt
3. Limit concurrent model instances
4. Scale to a larger GPU (update terraform/variables.tf)

## Prevention
- Alert when DCGM_FI_DEV_FB_USED > 90%
- Load test new models on staging before production
- Benchmark GPU memory before deploying new model versions
