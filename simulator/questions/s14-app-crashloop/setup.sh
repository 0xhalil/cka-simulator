reset_ns s14-ledger
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata: {name: ledger-config, namespace: s14-ledger}
data:
  log_level: debug
  ledger_region: eu-central
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: ledger-api, namespace: s14-ledger}
spec:
  replicas: 1
  selector: {matchLabels: {app: ledger-api}}
  template:
    metadata: {labels: {app: ledger-api}}
    spec:
      containers:
      - name: api
        image: nginx:1.27-alpine
        ports: [{name: http, containerPort: 80}]
        resources: {requests: {cpu: 10m, memory: 16Mi}, limits: {memory: 64Mi}}
        livenessProbe:
          httpGet: {path: /, port: 8080}
          initialDelaySeconds: 2
          periodSeconds: 3
          failureThreshold: 2
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: ledger-worker, namespace: s14-ledger}
spec:
  replicas: 1
  selector: {matchLabels: {app: ledger-worker}}
  template:
    metadata: {labels: {app: ledger-worker}}
    spec:
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh", "-c", "echo \"worker started, log level=$LOG_LEVEL\"; while true; do sleep 3600; done"]
        resources: {requests: {cpu: 5m, memory: 8Mi}, limits: {memory: 32Mi}}
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef: {name: ledger-config, key: LOG_LEVEL}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: ledger-cache, namespace: s14-ledger}
spec:
  replicas: 1
  selector: {matchLabels: {app: ledger-cache}}
  template:
    metadata: {labels: {app: ledger-cache}}
    spec:
      containers:
      - name: cache
        image: busybox:1.36
        command: ["sh", "-c", "CACHE=$(head -c 24m /dev/zero | tr '\\0' x); echo \"cache warmed: ${#CACHE} bytes\"; while true; do sleep 3600; done"]
        resources: {requests: {cpu: 5m, memory: 16Mi}, limits: {memory: 16Mi}}
YAML
mkdir -p /root/.s14 && kubectl -n s14-ledger get deploy ledger-api ledger-worker ledger-cache -o jsonpath='{.items[*].metadata.uid}' > /root/.s14/crashloop.uid
kubectl -n s14-ledger get deploy ledger-api ledger-worker ledger-cache -o jsonpath="{range .items[*]}{.spec.template.spec.containers[0].image}|{.spec.template.spec.containers[0].command}|{end}" | md5sum | cut -c1-8 > /root/.s14/crashloop.cmd
