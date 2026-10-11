cat <<'YAML' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata: {name: s08-fast}
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
apiVersion: v1
kind: Service
metadata: {name: kv, namespace: s08-kv}
spec:
  clusterIP: None
  selector: {app: kv}
  ports: [{port: 6379}]
---
apiVersion: apps/v1
kind: StatefulSet
metadata: {name: kv, namespace: s08-kv}
spec:
  serviceName: kv
  replicas: 2
  selector: {matchLabels: {app: kv}}
  template:
    metadata: {labels: {app: kv}}
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        command: [redis-server, --appendonly, "yes", --dir, /data]
        resources: {requests: {cpu: 5m, memory: 16Mi}}
        volumeMounts: [{name: data, mountPath: /data}]
  volumeClaimTemplates:
  - metadata: {name: data}
    spec:
      accessModes: [ReadWriteOnce]
      storageClassName: s08-fast
      resources: {requests: {storage: 64Mi}}
YAML
kubectl -n s08-kv rollout status sts kv --timeout=300s
kubectl -n s08-kv exec kv-0 -- redis-cli set owner cka
sleep 2
kubectl -n s08-kv delete pod kv-0
sleep 3
kubectl -n s08-kv wait --for=condition=Ready pod/kv-0 --timeout=300s
kubectl -n s08-kv exec kv-0 -- redis-cli get owner
