reset_ns s02-rs
course_dir s02-rs
# a stray pod that matches the backend selector -> will be adopted
kubectl -n s02-rs run backend-legacy --image=busybox:1.36 --labels=tier=backend,app=shop --restart=Never -- sleep 360000 >/dev/null
kubectl -n s02-rs wait --for=condition=Ready pod/backend-legacy --timeout=90s >/dev/null
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: ReplicaSet
metadata: {name: backend, namespace: s02-rs, labels: {app: shop}}
spec:
  replicas: 3
  selector: {matchLabels: {tier: backend}}
  template:
    metadata: {labels: {tier: backend, app: shop}}
    spec:
      containers:
      - name: httpd
        image: httpd:2.4-alpinee
        resources: {requests: {cpu: 5m, memory: 16Mi}}
YAML
cat > /opt/course/s02-rs/frontend-rs.yaml <<'YAML'
apiVersion: v1
kind: ReplicaSet
metadata:
  name: frontend
  namespace: s02-rs
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: front-end
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        resources:
          requests: {cpu: 5m, memory: 16Mi}
YAML
chown -R candidate: /opt/course/s02-rs
