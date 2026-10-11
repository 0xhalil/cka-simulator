course_dir mariadb
kubectl delete ns mariadb --ignore-not-found --wait=true >/dev/null 2>&1
kubectl delete pv mariadb-pv --ignore-not-found --wait=true >/dev/null 2>&1
on cka-w1 'rm -rf /mnt/data/mariadb; mkdir -p /mnt/data/mariadb; chmod 777 /mnt/data/mariadb'
kubectl create ns mariadb
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata: {name: mariadb-pv}
spec:
  capacity: {storage: 250Mi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  local: {path: /mnt/data/mariadb}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - {key: kubernetes.io/hostname, operator: In, values: [cka-w1]}
YAML
cat > /opt/course/mariadb/mariadb-deploy.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
  namespace: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:11.4
        env:
        - name: MARIADB_ROOT_PASSWORD
          value: rootpass
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mariadb-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mariadb-storage
        persistentVolumeClaim:
          claimName: ""
YAML
chown -R candidate: /opt/course
# pre-pull the image on the worker so the task is not dominated by download time
on cka-w1 'crictl pull docker.io/library/mariadb:11.4 >/dev/null' || true
