cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: canary-gw, namespace: s09-canary}
spec:
  gatewayClassName: nginx
  listeners:
  - {name: http, protocol: HTTP, port: 80, hostname: canary.s09.local}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: canary-route, namespace: s09-canary}
spec:
  parentRefs: [{name: canary-gw}]
  hostnames: [canary.s09.local]
  rules:
  - matches:
    - headers: [{name: X-Canary, value: always}]
    filters:
    - type: ResponseHeaderModifier
      responseHeaderModifier:
        add: [{name: X-Canary-Served, value: "true"}]
    backendRefs: [{name: app-v2, port: 80}]
  - backendRefs:
    - {name: app-v1, port: 80, weight: 80}
    - {name: app-v2, port: 80, weight: 20}
YAML
kubectl -n s09-canary wait --for=condition=Programmed gateway/canary-gw --timeout=180s
sleep 5
