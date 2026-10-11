cat <<'YAML' | kubectl apply -f -
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
YAML
kubectl -n web-app wait --for=condition=Programmed gateway/web-gateway --timeout=180s
kubectl -n web-app delete ingress web
