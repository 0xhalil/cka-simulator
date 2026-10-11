Node, PV, StorageClass are **cluster-scoped** resources → they can't be granted with Role/RoleBinding; you need **ClusterRole + ClusterRoleBinding**.
StorageClass is in the `storage.k8s.io` API group.

```bash
ssh cka-cp1
k create clusterrole s07-storage-admin --verb=get,list,watch --resource=nodes
k edit clusterrole s07-storage-admin
```
```yaml
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get","list","watch"]
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get","list","watch","create","delete"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get","list","watch"]
```
```bash
k create clusterrolebinding s07-storage-admin --clusterrole=s07-storage-admin --user=s07-alice

# find the source of the excess permissions
k get clusterrolebindings -o wide | grep s07-alice
#  s07-infra-legacy  ClusterRole/s07-infra-legacy  s07-bob, s07-alice  s07-infra-oncall
k edit clusterrolebinding s07-infra-legacy        # remove ONLY the s07-alice subject

k auth can-i delete nodes --as=s07-alice > /opt/course/s07-clusterrole/delete-nodes.txt              # no
k auth can-i create persistentvolumes --as=s07-alice > /opt/course/s07-clusterrole/create-pv.txt     # yes
```
Trap: deleting the whole binding also removes the permissions of `s07-bob` and the `s07-infra-oncall` group.
