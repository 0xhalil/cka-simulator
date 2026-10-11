reset_ns s09-canary
for v in v1 v2; do cat <<YAML | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: app-$v, namespace: s09-canary}
spec:
  replicas: 1
  selector: {matchLabels: {app: app, version: $v}}
  template:
    metadata: {labels: {app: app, version: $v}}
    spec:
      terminationGracePeriodSeconds: 1
      containers:
      - name: web
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /www && echo app-$v > /www/index.html && exec httpd -f -p 8080 -h /www"]
        ports: [{containerPort: 8080}]
        resources: {requests: {cpu: 5m, memory: 8Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: app-$v, namespace: s09-canary}
spec:
  selector: {app: app, version: $v}
  ports: [{name: http, port: 80, targetPort: 8080}]
YAML
done
wait_deploy s09-canary app-v1; wait_deploy s09-canary app-v2
