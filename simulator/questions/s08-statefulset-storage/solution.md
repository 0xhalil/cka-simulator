`volumeClaimTemplates` creates a separate PVC per replica (`<template>-<sts>-<ordinal>` → `data-kv-0`, `data-kv-1`). When a Pod is deleted it is recreated **with the same name** and binds to **the same PVC** → data is preserved. Because of `WaitForFirstConsumer` the PVCs stay Pending until the Pod is scheduled (normal).

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata: {name: s08-fast}
provisioner: rancher.io/local-path
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
apiVersion: v1
kind: Service
metadata: {name: kv, namespace: s08-kv}
spec:
  clusterIP: None
  selector: {app: kv}
  ports: [{port: 6379}]
---
apiVersion: apps/v1
kind: StatefulSet
metadata: {name: kv, namespace: s08-kv}
spec:
  serviceName: kv
  replicas: 2
  selector: {matchLabels: {app: kv}}
  template:
    metadata: {labels: {app: kv}}
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        command: ["redis-server","--appendonly","yes","--dir","/data"]
        volumeMounts: [{name: data, mountPath: /data}]
  volumeClaimTemplates:
  - metadata: {name: data}
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: s08-fast
      resources: {requests: {storage: 64Mi}}
```
```bash
ssh cka-cp1
k apply -f kv.yaml
k -n s08-kv get pvc                 # data-kv-0, data-kv-1 Bound
k -n s08-kv exec kv-0 -- redis-cli set owner cka
k -n s08-kv delete pod kv-0
k -n s08-kv exec kv-0 -- redis-cli get owner      # cka
```
Note: `allowVolumeExpansion: true` only allows it; actual expansion needs provisioner/CSI driver support (local-path doesn't support it).
