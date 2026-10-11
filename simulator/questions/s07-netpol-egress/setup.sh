reset_ns s07-np-app s07-np-web
R='resources: {requests: {cpu: 5m, memory: 16Mi}}'
cat <<YAML | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: api, namespace: s07-np-app}
spec:
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers: [{name: api, image: nginx:1.27-alpine, ports: [{containerPort: 80}], $R}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: db, namespace: s07-np-app}
spec:
  selector: {matchLabels: {app: db}}
  template:
    metadata: {labels: {app: db}}
    spec:
      containers: [{name: db, image: redis:7-alpine, ports: [{containerPort: 6379}], $R}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: cache, namespace: s07-np-app}
spec:
  selector: {matchLabels: {app: cache}}
  template:
    metadata: {labels: {app: cache}}
    spec:
      containers: [{name: cache, image: redis:7-alpine, ports: [{containerPort: 6379}], $R}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: frontend, namespace: s07-np-web}
spec:
  selector: {matchLabels: {role: frontend}}
  template:
    metadata: {labels: {role: frontend}}
    spec:
      containers: [{name: frontend, image: busybox:1.36, command: [sleep, 1d], $R}]
YAML
kubectl -n s07-np-app expose deploy api --port=80 >/dev/null
kubectl -n s07-np-app expose deploy db --port=6379 >/dev/null
kubectl -n s07-np-app expose deploy cache --port=6379 >/dev/null
for d in api db cache; do wait_deploy s07-np-app $d; done; wait_deploy s07-np-web frontend
