kubectl patch pv s08-archive-pv --type=json -p '[{"op":"remove","path":"/spec/claimRef"}]'
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: archive-restore, namespace: s08-archive}
spec:
  storageClassName: ""
  volumeName: s08-archive-pv
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 300Mi}}
---
apiVersion: v1
kind: Pod
metadata: {name: archive-reader, namespace: s08-archive}
spec:
  containers:
  - name: reader
    image: busybox:1.36
    command: [sleep, 1d]
    volumeMounts: [{name: archive, mountPath: /archive}]
  volumes:
  - name: archive
    persistentVolumeClaim: {claimName: archive-restore}
YAML
kubectl -n s08-archive wait --for=condition=Ready pod/archive-reader --timeout=300s
kubectl -n s08-archive exec archive-reader -- cat /archive/report-q3.txt > /opt/course/s08-archive/report-q3.txt
chown -R candidate: /opt/course/s08-archive
