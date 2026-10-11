"Pods are Running" ≠ "Service works". Check the chain: are the Pods **Ready** → does the Service **selector** match the pod labels → does **targetPort** reach the container port → are the endpoints populated.

Three errors:
1. **readinessProbe `port: web`** → the container has no port named `web` (it has `http`) → the probe fails, pods are `0/1 Running`, and a pod that isn't Ready can't become an endpoint.
2. **Service selector `tier: frontend`** → pods have `tier: edge` → no endpoints.
3. **Service `targetPort: web`** → a named targetPort must match the port **name** on the pod → `http` (or `80`).

Alternative: naming the container port `web` fixes both 1 and 3 — that's valid too.

```bash
k -n s14-relay get po --show-labels            # 0/1 Running, tier=edge
k -n s14-relay describe po -l app=relay | grep -i readiness
k -n s14-relay get svc relay-svc -o yaml       # selector + targetPort
k -n s14-relay get endpointslice -l kubernetes.io/service-name=relay-svc
k -n s14-relay edit deploy relay               # readinessProbe.httpGet.port: http
k -n s14-relay edit svc relay-svc              # selector tier: edge, targetPort: http
k run tmp --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- relay-svc.s14-relay
```
