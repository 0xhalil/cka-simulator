M=/etc/kubernetes/manifests/kube-scheduler.yaml
[ -f /root/kube-scheduler.yaml.orig ] || cp $M /root/kube-scheduler.yaml.orig
cp /root/kube-scheduler.yaml.orig $M
for i in $(seq 1 60); do kubectl -n kube-system get pod kube-scheduler-cka-cp2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q True && break; sleep 3; done
reset_ns ops
# break: wrong kubeconfig file name (scheduler crashes), applied outside the manifests dir first
sed 's#--kubeconfig=/etc/kubernetes/scheduler.conf#--kubeconfig=/etc/kubernetes/scheduler.config#' /root/kube-scheduler.yaml.orig > /tmp/ks.yaml
mv /tmp/ks.yaml $M
sleep 20
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: orbit, namespace: ops}
spec:
  replicas: 3
  selector: {matchLabels: {app: orbit}}
  template:
    metadata: {labels: {app: orbit}}
    spec:
      nodeSelector: {kubernetes.io/hostname: cka-cp2}
      tolerations: [{key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}]
      containers:
      - name: orbit
        image: busybox:1.36
        command: ["sleep", "1d"]
        resources: {requests: {cpu: 10m, memory: 8Mi}}
YAML
