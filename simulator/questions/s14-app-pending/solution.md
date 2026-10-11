Two Deployments, three independent causes. `kubectl describe pod` → **Events** (`FailedScheduling`) is always the first place to look.

**orbit-web** (two-layer error — fixing one reveals the other):
1. `nodeSelector: kubernetes.io/hostname: cka-worker1` → no such node (`didn't match Pod's node affinity/selector`). Changing the node is forbidden → remove the selector or set it to `cka-w1`.
2. `requests.cpu: "3"` → the worker has 2 CPUs (`Insufficient cpu`). Lower the request (e.g. `50m`), don't delete it.

**orbit-db**:
3. PVC `storageClassName: fast-ssd` → no such StorageClass, PVC `Pending` (`storageclass.storage.k8s.io "fast-ssd" not found`), pod `unbound immediate PersistentVolumeClaims`.
   Trap: the PVC's `storageClassName` is **immutable** → `kubectl edit` is rejected. Delete the PVC and recreate it with an existing class (`k get sc`). While a pod references the PVC, the `kubernetes.io/pvc-protection` finalizer can hold the deletion → scale `orbit-db` to 0 first.

```bash
k -n s14-orbit get po,pvc
k -n s14-orbit describe po -l app=orbit-web | grep -A3 Events
k -n s14-orbit edit deploy orbit-web       # remove nodeSelector, requests.cpu: 50m
k get sc
k -n s14-orbit get pvc orbit-data -o yaml > pvc.yaml
# pvc.yaml: storageClassName: local-path ; remove status/uid/resourceVersion
k -n s14-orbit scale deploy orbit-db --replicas=0
k -n s14-orbit delete pvc orbit-data
k apply -f pvc.yaml
k -n s14-orbit scale deploy orbit-db --replicas=1
k -n s14-orbit get po,pvc -w
```
