course_dir s07-rbac
reset_ns s07-apps
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata: {name: app, namespace: s07-apps, labels: {app: app}}
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: [sh, -c, 'echo "s07 app started token=ZX81-support"; while true; do echo "$(date) heartbeat"; sleep 30; done']
---
apiVersion: v1
kind: Pod
metadata: {name: debug-shell, namespace: s07-apps}
spec:
  containers: [{name: shell, image: busybox:1.36, command: [sleep, 1d]}]
---
apiVersion: v1
kind: Pod
metadata: {name: payments, namespace: s07-apps}
spec:
  containers: [{name: payments, image: busybox:1.36, command: [sleep, 1d]}]
---
apiVersion: v1
kind: ConfigMap
metadata: {name: app-config, namespace: s07-apps}
data: {LOG_LEVEL: info}
---
apiVersion: v1
kind: ConfigMap
metadata: {name: payment-keys, namespace: s07-apps}
data: {GATEWAY: internal}
YAML
kubectl -n s07-apps wait --for=condition=Ready pod --all --timeout=90s >/dev/null
