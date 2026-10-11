```bash
ssh cka-cp1
k -n s08-shop get pod                         # Pending
k -n s08-shop describe pod -l app=orders      # pod has unbound immediate PersistentVolumeClaims
k -n s08-shop describe pvc orders-data        # storageclass "s08-manaul" not found
k get pv s08-orders-pv -o yaml                # 200Mi, RWO, storageClassName s08-manual
```
The PVC has **three** mismatches: StorageClass name typo (`s08-manaul`), access mode `ReadWriteMany` (PV is RWO only), request `500Mi` (> 200Mi).
The PVC spec (class, accessModes) is **immutable** → delete and recreate (because a Pod uses it, the delete is held by the `kubernetes.io/pvc-protection` finalizer, but it completes immediately since the pod doesn't exist; scale the deployment to 0 if needed).

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: orders-data, namespace: s08-shop}
spec:
  storageClassName: s08-manual
  volumeName: s08-orders-pv        # optional, but prevents mixing it up with the 100Mi PV in the same class
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 200Mi}}
```
```bash
k -n s08-shop delete pvc orders-data
k apply -f pvc.yaml
k -n s08-shop get pvc                     # Bound s08-orders-pv
k -n s08-shop rollout status deploy orders
k -n s08-shop exec deploy/orders -- wget -qO- localhost
```
Trap: lowering the request to 100Mi could bind the PVC to `s08-orders-archive` (wrong data).
