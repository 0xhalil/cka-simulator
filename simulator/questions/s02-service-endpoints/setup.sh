reset_ns s02-svc
course_dir s02-svc
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: orders, namespace: s02-svc}
spec:
  replicas: 2
  selector: {matchLabels: {app: orders, track: stable}}
  template:
    metadata: {labels: {app: orders, track: stable}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        ports: [{name: web, containerPort: 80}]
        resources: {requests: {cpu: 5m, memory: 16Mi}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: orders-canary, namespace: s02-svc}
spec:
  replicas: 1
  selector: {matchLabels: {app: orders, track: canary}}
  template:
    metadata: {labels: {app: orders, track: canary}}
    spec:
      containers:
      - name: httpd
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /www && echo canary-build > /www/index.html && httpd -f -p 80 -h /www"]
        ports: [{name: web, containerPort: 80}]
        resources: {requests: {cpu: 5m, memory: 8Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: orders-svc, namespace: s02-svc}
spec:
  type: ClusterIP
  selector: {app: order}
  ports:
  - name: http
    port: 8080
    targetPort: 8080
YAML
wait_deploy s02-svc orders 120s; wait_deploy s02-svc orders-canary 120s
true
