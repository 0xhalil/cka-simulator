kubectl label node cka-w1 cka-cp1 s03.cka.local/disktype- s03.cka.local/zone- >/dev/null 2>&1
reset_ns s03-affinity
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: ssd-cache, namespace: s03-affinity}
spec:
  replicas: 2
  selector: {matchLabels: {app: ssd-cache}}
  template:
    metadata: {labels: {app: ssd-cache}}
    spec:
      nodeSelector: {disk: ssd}
      containers:
      - name: cache
        image: redis:7-alpine
        resources: {requests: {cpu: 10m, memory: 16Mi}, limits: {memory: 64Mi}}
YAML
