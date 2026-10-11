course_dir s09-dns
reset_ns s09-dns s09-dns-client
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: catalog, namespace: s09-dns}
spec:
  replicas: 1
  selector: {matchLabels: {app: catalog}}
  template:
    metadata: {labels: {app: catalog}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        resources: {requests: {cpu: 5m, memory: 16Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: catalog, namespace: s09-dns}
spec:
  selector: {app: catalog}
  ports: [{port: 80}]
---
apiVersion: apps/v1
kind: StatefulSet
metadata: {name: ledger, namespace: s09-dns}
spec:
  serviceName: ledger-hl
  replicas: 2
  selector: {matchLabels: {app: ledger}}
  template:
    metadata: {labels: {app: ledger}}
    spec:
      terminationGracePeriodSeconds: 1
      containers:
      - name: ledger
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /www && hostname > /www/index.html && exec httpd -f -p 80 -h /www"]
        resources: {requests: {cpu: 5m, memory: 8Mi}}
---
apiVersion: v1
kind: Pod
metadata: {name: client, namespace: s09-dns-client}
spec:
  terminationGracePeriodSeconds: 1
  containers:
  - name: client
    image: busybox:1.36
    command: ["sleep", "infinity"]
    resources: {requests: {cpu: 5m, memory: 8Mi}}
YAML
wait_deploy s09-dns catalog
kubectl -n s09-dns rollout status sts ledger --timeout=180s >/dev/null
kubectl -n s09-dns-client wait --for=condition=Ready pod/client --timeout=120s >/dev/null
