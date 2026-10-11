reset_ns s03-quota
course_dir s03-quota
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: api, namespace: s03-quota}
spec:
  replicas: 3
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
      - name: api
        image: nginx:1.27-alpine
YAML
wait_deploy s03-quota api 120s
