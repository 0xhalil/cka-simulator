kubectl get node cka-cp1 -o jsonpath='{range .spec.taints[*]}{.key}:{.effect}{"\n"}{end}' > /opt/course/s03-ds/cp-taints.txt
kubectl -n s03-ds patch ds node-exporter-lite --type=json -p '[{"op":"replace","path":"/spec/template/spec/tolerations","value":[{"key":"node-role.kubernetes.io/control-plane","operator":"Exists","effect":"NoSchedule"}]}]'
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata: {name: log-shipper, namespace: s03-ds}
spec:
  selector: {matchLabels: {app: log-shipper}}
  template:
    metadata: {labels: {app: log-shipper}}
    spec:
      nodeSelector: {node-role.kubernetes.io/control-plane: ""}
      tolerations:
      - {key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}
      containers:
      - name: shipper
        image: busybox:1.36
        command: ["sh", "-c", "tail -F /host/log/syslog"]
        resources: {requests: {cpu: 5m, memory: 16Mi}}
        volumeMounts: [{name: varlog, mountPath: /host/log, readOnly: true}]
      volumes:
      - {name: varlog, hostPath: {path: /var/log}}
YAML
kubectl -n s03-ds rollout status ds node-exporter-lite --timeout=90s
kubectl -n s03-ds rollout status ds log-shipper --timeout=90s
