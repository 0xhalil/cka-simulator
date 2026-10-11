The team owning namespace `s03-quota` must be restricted. A Deployment `api` (3 replicas) is already running there.

1. Create a LimitRange named `container-limits` in namespace `s03-quota` for **containers**:
   - default **limits**: CPU `200m`, memory `128Mi`
   - default **requests**: CPU `50m`, memory `32Mi`
   - **maximum**: CPU `500m`, memory `256Mi`
2. Create a ResourceQuota named `team-quota` in namespace `s03-quota` with: `requests.cpu=500m`, `requests.memory=512Mi`, `limits.cpu=1`, `limits.memory=1Gi`, `pods=6`.
3. Make sure all 3 Pods of Deployment `api` are running **with the defaults of the LimitRange applied**. Do not add resources to the Deployment's Pod template.
4. Try to create a Pod named `oversized` (image `nginx:1.27-alpine`) in namespace `s03-quota` with a CPU **limit** of `1`. Write the error message returned by the API server into `/opt/course/s03-quota/oversized.txt`. The Pod must not exist afterwards.
