When the PVC is deleted, a PV with `Retain` policy becomes **Released**: the data stays, but since `spec.claimRef` still points to the old (deleted) PVC (by its uid), it won't bind to any new PVC.
Fix: remove `claimRef` (PV → **Available**) or change it to point to the new PVC. No need to delete and recreate the PV.

```bash
ssh cka-cp1
k get pv s08-archive-pv                  # STATUS Released, CLAIM s08-legacy/archive
k patch pv s08-archive-pv --type=json -p '[{"op":"remove","path":"/spec/claimRef"}]'
k get pv s08-archive-pv                  # Available
```
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: archive-restore, namespace: s08-archive}
spec:
  storageClassName: ""          # PV class is "" -> if you omit it the default SC is assigned and a new volume is provisioned!
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
    command: ["sleep","1d"]
    volumeMounts: [{name: archive, mountPath: /archive}]
  volumes:
  - name: archive
    persistentVolumeClaim: {claimName: archive-restore}
```
```bash
k apply -f restore.yaml
k -n s08-archive exec archive-reader -- cat /archive/report-q3.txt > /opt/course/s08-archive/report-q3.txt
```
