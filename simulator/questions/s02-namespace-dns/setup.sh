reset_ns s02-frontend s02-backend
course_dir s02-dns
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: redis, namespace: s02-backend}
spec:
  replicas: 1
  selector: {matchLabels: {app: redis}}
  template:
    metadata: {labels: {app: redis}}
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports: [{containerPort: 6379}]
        resources: {requests: {cpu: 5m, memory: 16Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: cache, namespace: s02-backend}
spec:
  selector: {app: redis}
  ports: [{port: 6379, targetPort: 6379}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: webapp, namespace: s02-frontend}
spec:
  replicas: 2
  selector: {matchLabels: {app: webapp}}
  template:
    metadata: {labels: {app: webapp}}
    spec:
      containers:
      - name: app
        image: busybox:1.36
        env: [{name: CACHE_HOST, value: cache}]
        command: ["sh", "-c", "while true; do if nc -z -w 2 $CACHE_HOST 6379; then touch /tmp/ready; else rm -f /tmp/ready; echo \"cannot reach $CACHE_HOST:6379\"; fi; sleep 3; done"]
        readinessProbe:
          exec: {command: ["cat", "/tmp/ready"]}
          periodSeconds: 3
YAML
wait_deploy s02-backend redis 120s
true
