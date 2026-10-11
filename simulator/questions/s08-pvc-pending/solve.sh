kubectl -n s08-shop delete pvc orders-data --wait=false
kubectl -n s08-shop wait --for=delete pvc/orders-data --timeout=60s
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: orders-data, namespace: s08-shop}
spec:
  storageClassName: s08-manual
  volumeName: s08-orders-pv
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 200Mi}}
YAML
kubectl -n s08-shop rollout status deploy orders --timeout=240s
