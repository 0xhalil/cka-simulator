course_dir s08-archive
kubectl delete ns s08-archive s08-legacy --ignore-not-found --wait=true --timeout=120s >/dev/null 2>&1
kubectl delete pv s08-archive-pv --ignore-not-found --wait=true >/dev/null 2>&1
on cka-w1 'rm -rf /mnt/s08-archive; mkdir -p /mnt/s08-archive; echo "quarterly report Q3 total=98213 checksum=s08-$(date +%s)" > /mnt/s08-archive/report-q3.txt'
kubectl create ns s08-legacy >/dev/null
kubectl create ns s08-archive >/dev/null
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolume
metadata: {name: s08-archive-pv}
spec:
  capacity: {storage: 300Mi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  local: {path: /mnt/s08-archive}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions: [{key: kubernetes.io/hostname, operator: In, values: [cka-w1]}]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: archive, namespace: s08-legacy}
spec:
  storageClassName: ""
  volumeName: s08-archive-pv
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 300Mi}}
YAML
kubectl wait --for=jsonpath='{.status.phase}'=Bound pv/s08-archive-pv --timeout=60s >/dev/null
kubectl delete ns s08-legacy --wait=true --timeout=120s >/dev/null
kubectl wait --for=jsonpath='{.status.phase}'=Released pv/s08-archive-pv --timeout=60s >/dev/null
mkdir -p /var/lib/cka-sim && kubectl get pv s08-archive-pv -o jsonpath='{.metadata.uid}' > /var/lib/cka-sim/s08-archive-pv.uid
