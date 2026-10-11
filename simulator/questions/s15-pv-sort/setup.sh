course_dir s15-pv
kubectl delete pv -l report=s15 --wait=true --timeout=60s >/dev/null 2>&1
mk() {  # name size policy
cat <<YAML | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolume
metadata: {name: $1, labels: {report: s15}}
spec:
  capacity: {storage: $2}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: $3
  storageClassName: s15-manual
  hostPath: {path: /tmp/$1}
YAML
}
mk s15-pv-logs 500Mi Retain
mk s15-pv-media 2Gi Delete
mk s15-pv-db 1Gi Retain
mk s15-pv-tmp 100Mi Delete
mk s15-pv-archive 1536Mi Retain
mk s15-pv-cache 768Mi Delete
true
