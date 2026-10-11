reset_ns s03-ds
course_dir s03-ds
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata: {name: node-exporter-lite, namespace: s03-ds}
spec:
  selector: {matchLabels: {app: node-exporter-lite}}
  template:
    metadata: {labels: {app: node-exporter-lite}}
    spec:
      tolerations:
      - {key: node-role.kubernetes.io/master, operator: Exists, effect: NoSchedule}
      containers:
      - name: exporter
        image: busybox:1.36
        command: ["sh", "-c", "while true; do cat /proc/loadavg; sleep 30; done"]
        resources: {requests: {cpu: 5m, memory: 8Mi}}
YAML
