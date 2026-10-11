reset_ns s03-manual
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: manual-web, namespace: s03-manual, labels: {app: manual-web, tier: frontend}}
spec:
  schedulerName: s03-offline-scheduler
  containers:
  - name: web
    image: nginx:1.27-alpine
    ports: [{containerPort: 80}]
    resources: {requests: {cpu: 10m, memory: 16Mi}}
---
apiVersion: v1
kind: Pod
metadata: {name: manual-api, namespace: s03-manual, labels: {app: manual-api}}
spec:
  schedulerName: s03-offline-scheduler
  containers:
  - name: api
    image: busybox:1.36
    command: ["sh", "-c", "while true; do echo api alive; sleep 15; done"]
    resources: {requests: {cpu: 10m, memory: 16Mi}}
YAML
kubectl -n s03-manual get pod manual-api -o jsonpath='{.metadata.uid}' > /root/.s03-manual-api.uid
