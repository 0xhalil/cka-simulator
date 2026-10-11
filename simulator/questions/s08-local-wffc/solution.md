- `kubernetes.io/no-provisioner` = no dynamic provisioning; you create the PV manually.
- `WaitForFirstConsumer` → the PVC stays **Pending** until a Pod using it is scheduled (event: `waiting for first consumer to be created before binding`). Not an error!
- `nodeAffinity` is **mandatory** on a `local` PV; thanks to it the scheduler automatically places the Pod on `cka-w1` (no nodeName/nodeSelector needed). `hostPath` carries no node information.

```yaml
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
  local:
    path: /mnt/s08-local
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - {key: kubernetes.io/hostname, operator: In, values: [cka-w1]}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: local-claim, namespace: s08-local}
spec:
  storageClassName: s08-local
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 128Mi}}
```
```bash
ssh cka-cp1
k apply -f local.yaml
k -n s08-local get pvc local-claim -o jsonpath='{.status.phase}' > /opt/course/s08-local/pvc-phase.txt   # Pending
k -n s08-local describe pvc local-claim       # WaitForFirstConsumer
k apply -f pod.yaml                            # Pod -> cka-w1, PVC -> Bound
ssh cka-w1 cat /mnt/s08-local/hello.txt
```
