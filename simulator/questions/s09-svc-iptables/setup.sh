course_dir s09-orbit
reset_ns s09-orbit
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: orbit-api, namespace: s09-orbit, labels: {app: orbit-api}}
spec:
  replicas: 2
  selector: {matchLabels: {app: orbit-api, tier: backend}}
  template:
    metadata: {labels: {app: orbit-api, tier: backend}}
    spec:
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /www && echo orbit-api: $(hostname) > /www/index.html && exec httpd -f -p 8080 -h /www"]
        ports: [{name: web, containerPort: 8080}]
        resources: {requests: {cpu: 5m, memory: 8Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: orbit-svc, namespace: s09-orbit}
spec:
  selector: {app: orbit-api, tier: back-end}
  ports: [{name: http, port: 80, targetPort: 80}]
YAML
wait_deploy s09-orbit orbit-api
