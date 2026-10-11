reset_ns resources
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: web-portal, namespace: resources}
spec:
  replicas: 3
  selector: {matchLabels: {app: web-portal}}
  template:
    metadata: {labels: {app: web-portal}}
    spec:
      nodeSelector: {kubernetes.io/hostname: cka-w1}
      initContainers:
      - name: init-config
        image: busybox:1.36
        command: ["sh", "-c", "echo preparing config; sleep 2"]
        resources: {requests: {cpu: 100m, memory: 64Mi}}
      containers:
      - name: portal
        image: nginx:1.27-alpine
        resources: {requests: {cpu: 800m, memory: 700Mi}}
YAML
