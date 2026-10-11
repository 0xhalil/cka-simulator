The Service is broken in two places:
1. **selector** `app: order` (typo) — matches no Pods, Endpoints are empty. But just writing `app: orders` is also a **trap**: the canary Pod carries `app: orders` too and would receive traffic. The selector must be `app: orders` + `track: stable`.
2. **targetPort** `8080` — the nginx container listens on 80 (port name `web`). `port` (the Service's port, 8080) and `targetPort` (the container port) are different things.

```bash
ssh cka-cp1
k -n s02-svc get pod --show-labels -o wide
k -n s02-svc describe svc orders-svc        # Endpoints: <none>
k -n s02-svc edit svc orders-svc
```
```yaml
spec:
  type: ClusterIP
  selector:
    app: orders
    track: stable
  ports:
  - name: http
    port: 8080
    targetPort: web        # or 80
```
```bash
k -n s02-svc get endpointslice -l kubernetes.io/service-name=orders-svc -o wide
k -n s02-svc get endpointslice -l kubernetes.io/service-name=orders-svc \
  -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{"\n"}{end}' > /opt/course/s02-svc/endpoints.txt
k -n s02-svc run tmp --rm -it --image=busybox:1.36 --restart=Never -- wget -qO- orders-svc:8080
```
