cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: mariadb, namespace: mariadb}
spec:
  storageClassName: ""
  volumeName: mariadb-pv
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 250Mi}}
YAML
sed -i 's/claimName: ""/claimName: mariadb/' /opt/course/mariadb/mariadb-deploy.yaml
kubectl apply -f /opt/course/mariadb/mariadb-deploy.yaml
kubectl -n mariadb rollout status deploy mariadb --timeout=180s
