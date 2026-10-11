```bash
ssh cka-cp1
k -n web-app get ingress web -o yaml      # TLS: secret web-tls, rule: / (Prefix) -> web-svc:80
```
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: web-gateway, namespace: web-app}
spec:
  gatewayClassName: nginx
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: gateway.web.k8s.local
    tls:
      mode: Terminate
      certificateRefs: [{kind: Secret, name: web-tls}]
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: web-route, namespace: web-app}
spec:
  parentRefs: [{name: web-gateway}]
  hostnames: ["gateway.web.k8s.local"]
  rules:
  - matches: [{path: {type: PathPrefix, value: /}}]
    backendRefs: [{name: web-svc, port: 80}]
```
```bash
k apply -f gw.yaml
k -n web-app get gateway,httproute
k -n web-app get svc                              # web-gateway-nginx  NodePort 443:3xxxx
curl -k --resolve gateway.web.k8s.local:3xxxx:<nodeIP> https://gateway.web.k8s.local:3xxxx/
k -n web-app delete ingress web
```
