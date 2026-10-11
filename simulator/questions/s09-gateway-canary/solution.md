```yaml
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
  - matches:                                   # header match
    - headers: [{name: X-Canary, value: always}]
    filters:
    - type: ResponseHeaderModifier
      responseHeaderModifier:
        add: [{name: X-Canary-Served, value: "true"}]
    backendRefs: [{name: app-v2, port: 80}]
  - backendRefs:                               # no match = PathPrefix /
    - {name: app-v1, port: 80, weight: 80}
    - {name: app-v2, port: 80, weight: 20}
```
```bash
ssh cka-cp1
k apply -f canary.yaml
k -n s09-canary get gateway,httproute
k -n s09-canary get svc -l gateway.networking.k8s.io/gateway-name=canary-gw   # canary-gw-nginx 80:3xxxx
for i in $(seq 20); do curl -s -H 'Host: canary.s09.local' http://<nodeIP>:3xxxx/; done | sort | uniq -c
curl -si -H 'Host: canary.s09.local' -H 'X-Canary: always' http://<nodeIP>:3xxxx/
```
Notes: with Ingress this would need controller-specific annotations; in Gateway API weights (`weight`) and header matching are part of the spec. The header rule is more specific, so it takes precedence. Weights are proportional (80/20 = 4/1). The `X-Canary-Served` value must be a string (`"true"`).
