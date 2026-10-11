kubectl delete ns s08-shop --ignore-not-found --wait=true --timeout=120s >/dev/null 2>&1
kubectl delete pv s08-orders-pv s08-orders-archive --ignore-not-found --wait=true >/dev/null 2>&1
on cka-w1 'rm -rf /mnt/s08-orders /mnt/s08-orders-archive; mkdir -p /mnt/s08-orders /mnt/s08-orders-archive; echo "s08 shop orders: 4711 open" > /mnt/s08-orders/index.html; echo old > /mnt/s08-orders-archive/index.html; chmod -R 755 /mnt/s08-orders /mnt/s08-orders-archive'
kubectl create ns s08-shop >/dev/null
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolume
metadata: {name: s08-orders-pv, labels: {app: orders}}
spec:
  capacity: {storage: 200Mi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: s08-manual
  local: {path: /mnt/s08-orders}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions: [{key: kubernetes.io/hostname, operator: In, values: [cka-w1]}]
---
apiVersion: v1
kind: PersistentVolume
metadata: {name: s08-orders-archive, labels: {app: orders}}
spec:
  capacity: {storage: 100Mi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: s08-manual
  local: {path: /mnt/s08-orders-archive}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions: [{key: kubernetes.io/hostname, operator: In, values: [cka-w1]}]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: orders-data, namespace: s08-shop}
spec:
  storageClassName: s08-manaul
  accessModes: [ReadWriteMany]
  resources: {requests: {storage: 500Mi}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: orders, namespace: s08-shop}
spec:
  replicas: 1
  strategy: {type: Recreate}
  selector: {matchLabels: {app: orders}}
  template:
    metadata: {labels: {app: orders}}
    spec:
      containers:
      - name: web
        image: nginx:1.27-alpine
        resources: {requests: {cpu: 5m, memory: 16Mi}}
        volumeMounts: [{name: data, mountPath: /usr/share/nginx/html}]
      volumes:
      - name: data
        persistentVolumeClaim: {claimName: orders-data}
YAML
