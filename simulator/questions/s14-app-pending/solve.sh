N=s14-orbit
kubectl -n $N patch deploy orbit-web --type=json -p '[{"op":"remove","path":"/spec/template/spec/nodeSelector"},{"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/cpu","value":"50m"}]'
kubectl -n $N scale deploy orbit-db --replicas=0
kubectl -n $N delete pvc orbit-data --timeout=60s
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: orbit-data, namespace: s14-orbit}
spec:
  storageClassName: local-path
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 100Mi}}
YAML
kubectl -n $N scale deploy orbit-db --replicas=1
kubectl -n $N rollout status deploy/orbit-web --timeout=120s
kubectl -n $N rollout status deploy/orbit-db --timeout=180s
