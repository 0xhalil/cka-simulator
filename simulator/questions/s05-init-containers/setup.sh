reset_ns s05-init
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: orders-db, namespace: s05-init}
spec:
  replicas: 1
  selector: {matchLabels: {app: orders-db}}
  template:
    metadata: {labels: {app: orders-db}}
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports: [{containerPort: 6379}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: orders, namespace: s05-init}
spec:
  replicas: 1
  selector: {matchLabels: {app: orders}}
  template:
    metadata: {labels: {app: orders}}
    spec:
      initContainers:
      - name: wait-for-db
        image: busybox:1.36
        command: ["sh", "-c", "until nslookup orders-db.s05-init.svc.cluster.local; do echo waiting for orders-db; sleep 2; done"]
      - name: migrate
        image: busybox:1.36
        command: ["sh", "-c", "echo 'migration done' > /work/migrated"]
      containers:
      - name: orders
        image: busybox:1.36
        command: ["sh", "-c", "cat /work/migrated && sleep 1d"]
YAML
wait_deploy s05-init orders-db
