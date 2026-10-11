reset_ns s14-orbit
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: orbit-web, namespace: s14-orbit}
spec:
  replicas: 2
  selector: {matchLabels: {app: orbit-web}}
  template:
    metadata: {labels: {app: orbit-web}}
    spec:
      nodeSelector:
        kubernetes.io/hostname: cka-worker1
      containers:
      - name: web
        image: nginx:1.27-alpine
        ports: [{containerPort: 80}]
        resources:
          requests: {cpu: "3", memory: 16Mi}
          limits: {memory: 64Mi}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: orbit-data, namespace: s14-orbit}
spec:
  storageClassName: fast-ssd
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 100Mi}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: orbit-db, namespace: s14-orbit}
spec:
  replicas: 1
  strategy: {type: Recreate}
  selector: {matchLabels: {app: orbit-db}}
  template:
    metadata: {labels: {app: orbit-db}}
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        args: ["--appendonly", "yes", "--dir", "/data"]
        ports: [{containerPort: 6379}]
        resources:
          requests: {cpu: 10m, memory: 16Mi}
          limits: {memory: 96Mi}
        volumeMounts: [{name: data, mountPath: /data}]
      volumes:
      - name: data
        persistentVolumeClaim: {claimName: orbit-data}
YAML
# pre-pull redis on the worker so the task is not dominated by download time
on cka-w1 'crictl pull docker.io/library/redis:7-alpine >/dev/null' || true
