reset_ns s05-cmd
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: sleeper, namespace: s05-cmd}
spec:
  replicas: 1
  selector: {matchLabels: {app: sleeper}}
  template:
    metadata: {labels: {app: sleeper}}
    spec:
      containers:
      - name: sleeper
        image: busybox:1.36
        command: ["sleep 3600"]
        resources: {requests: {cpu: 5m, memory: 8Mi}}
YAML
