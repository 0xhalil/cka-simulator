```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-retain
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
```
```bash
ssh cka-cp1
k apply -f sc.yaml
k patch sc local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
k get sc                                   # only local-retain (default)
k create ns storage-test 2>/dev/null
# PVC (no storageClassName) + Pod -> because of WaitForFirstConsumer it becomes Bound once the Pod is scheduled
```
