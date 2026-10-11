cat <<'YAML' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata: {name: s08-local}
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata: {name: s08-local-pv}
spec:
  capacity: {storage: 128Mi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: s08-local
  local: {path: /mnt/s08-local}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions: [{key: kubernetes.io/hostname, operator: In, values: [cka-w1]}]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: local-claim, namespace: s08-local}
spec:
  storageClassName: s08-local
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 128Mi}}
YAML
sleep 2
kubectl -n s08-local get pvc local-claim -o jsonpath='{.status.phase}' > /opt/course/s08-local/pvc-phase.txt
chown candidate: /opt/course/s08-local/pvc-phase.txt
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: local-writer, namespace: s08-local}
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: [sh, -c, 'echo "written by $(hostname)" > /data/hello.txt; sleep 1d']
    volumeMounts: [{name: data, mountPath: /data}]
  volumes:
  - name: data
    persistentVolumeClaim: {claimName: local-claim}
YAML
kubectl -n s08-local wait --for=condition=Ready pod/local-writer --timeout=300s
