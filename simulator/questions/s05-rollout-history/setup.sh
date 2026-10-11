reset_ns s05-rollout
course_dir s05-rollout
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: s05-rollout
  annotations: {kubernetes.io/change-cause: "release v1"}
spec:
  replicas: 4
  selector: {matchLabels: {app: web}}
  template:
    metadata: {labels: {app: web}}
    spec:
      terminationGracePeriodSeconds: 5
      containers:
      - name: web
        image: nginx:1.27-alpine
        env: [{name: APP_VERSION, value: "1"}]
        resources: {requests: {cpu: 5m, memory: 16Mi}}
YAML
wait_deploy s05-rollout web
rel() {  # $1 change-cause, $2 version, $3 image
  kubectl -n s05-rollout patch deploy web --type=strategic -p "{\"metadata\":{\"annotations\":{\"kubernetes.io/change-cause\":\"$1\"}},\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"web\",\"image\":\"$3\",\"env\":[{\"name\":\"APP_VERSION\",\"value\":\"$2\"}]}]}}}}"
}
rel "release v2-stable" 2 nginx:1.27-alpine; wait_deploy s05-rollout web
rel "release v3" 3 nginx:1.27-alpine; wait_deploy s05-rollout web
rel "release v4" 4 nginx:1.27-alpine-hotfix
sleep 3
kubectl -n s05-rollout get deploy web -o jsonpath='{.metadata.uid}' > /root/.s05-rollout-web.uid
kubectl -n s05-rollout rollout history deploy web
