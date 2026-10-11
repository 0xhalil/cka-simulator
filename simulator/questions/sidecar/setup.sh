reset_ns sidecar
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: logger-app, namespace: sidecar}
spec:
  replicas: 1
  selector: {matchLabels: {app: logger-app}}
  template:
    metadata: {labels: {app: logger-app}}
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["/bin/sh", "-c", "i=0; while true; do i=$((i+1)); echo \"$(date) legacy-app processed order $i\" >> /var/log/app.log; sleep 3; done"]
YAML
