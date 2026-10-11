PV has `storageClassName: ""` → the PVC must also set `storageClassName: ""` **explicitly**. If you omit it, the cluster's default StorageClass (local-path) is assigned, a new volume is provisioned dynamically, and it does not bind to `mariadb-pv`.

```bash
ssh cka-cp1
k get pv mariadb-pv -o yaml
```
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: mariadb, namespace: mariadb}
spec:
  storageClassName: ""
  volumeName: mariadb-pv          # optional but explicit
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 250Mi}}
```
```bash
k apply -f pvc.yaml && k -n mariadb get pvc     # Bound mariadb-pv
vim /opt/course/mariadb/mariadb-deploy.yaml     # claimName: mariadb
k apply -f /opt/course/mariadb/mariadb-deploy.yaml
k -n mariadb rollout status deploy mariadb
```
