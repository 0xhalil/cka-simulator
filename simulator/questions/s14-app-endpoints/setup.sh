reset_ns s14-relay
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: relay, namespace: s14-relay}
spec:
  replicas: 3
  selector: {matchLabels: {app: relay}}
  template:
    metadata: {labels: {app: relay, tier: edge}}
    spec:
      containers:
      - name: relay
        image: httpd:2.4-alpine
        ports: [{name: http, containerPort: 80}]
        readinessProbe:
          httpGet: {path: /, port: web}
          periodSeconds: 3
        resources: {requests: {cpu: 5m, memory: 16Mi}, limits: {memory: 64Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: relay-svc, namespace: s14-relay}
spec:
  selector: {app: relay, tier: frontend}
  ports: [{name: http, port: 80, targetPort: web}]
YAML
mkdir -p /root/.s14 && kubectl -n s14-relay get deploy/relay svc/relay-svc -o jsonpath='{.items[*].metadata.uid}' > /root/.s14/endpoints.uid
