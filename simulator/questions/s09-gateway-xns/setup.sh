reset_ns s09-gw-infra s09-gw-team s09-gw-backend
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: shared-gw, namespace: s09-gw-infra}
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: portal.s09.local
    allowedRoutes:
      namespaces: {from: Same}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: portal-api, namespace: s09-gw-backend}
spec:
  replicas: 1
  selector: {matchLabels: {app: portal-api}}
  template:
    metadata: {labels: {app: portal-api}}
    spec:
      terminationGracePeriodSeconds: 1
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /www/api && echo portal-api root > /www/index.html && echo portal-api v1 > /www/api/index.html && exec httpd -f -p 8080 -h /www"]
        ports: [{containerPort: 8080}]
        resources: {requests: {cpu: 5m, memory: 8Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: portal-api, namespace: s09-gw-backend}
spec:
  selector: {app: portal-api}
  ports: [{name: http, port: 80, targetPort: 8080}]
YAML
wait_deploy s09-gw-backend portal-api
kubectl -n s09-gw-infra wait --for=condition=Programmed gateway/shared-gw --timeout=180s >/dev/null
