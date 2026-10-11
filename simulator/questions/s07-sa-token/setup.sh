course_dir s07-sa
reset_ns s07-sa
kubectl -n s07-sa create sa batch-runner >/dev/null
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: scanner, namespace: s07-sa}
spec:
  replicas: 1
  selector: {matchLabels: {app: scanner}}
  template:
    metadata: {labels: {app: scanner}}
    spec:
      containers:
      - {name: scanner, image: busybox:1.36, command: [sleep, 1d], resources: {requests: {cpu: 5m, memory: 8Mi}}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: batch, namespace: s07-sa}
spec:
  replicas: 1
  selector: {matchLabels: {app: batch}}
  template:
    metadata: {labels: {app: batch}}
    spec:
      serviceAccountName: batch-runner
      containers:
      - {name: batch, image: busybox:1.36, command: [sleep, 1d], resources: {requests: {cpu: 5m, memory: 8Mi}}}
YAML
wait_deploy s07-sa scanner; wait_deploy s07-sa batch
