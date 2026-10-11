reset_ns autoscale
cat <<YAML | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: apache-server, namespace: autoscale, labels: {app: apache-server}}
spec:
  replicas: 1
  selector: {matchLabels: {app: apache-server}}
  template:
    metadata: {labels: {app: apache-server}}
    spec:
      containers:
      - name: httpd
        image: httpd:2.4-alpine
        resources: {requests: {cpu: 100m, memory: 32Mi}, limits: {cpu: 200m, memory: 64Mi}}
YAML
