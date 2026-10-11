# 07 — Storage

Scope: volumes (emptyDir, hostPath), PersistentVolume, PersistentVolumeClaim, access modes, reclaim policy, StorageClass, dynamic provisioning, `WaitForFirstConsumer`, volume expansion, CSI.

---

## Q1 — Static PV + PVC + Pod (6%)

1. Create PV `pv-logs`: capacity `1Gi`, access mode `ReadWriteOnce`, reclaim policy `Retain`, `hostPath` `/mnt/data/logs`, storageClassName `manual`.
2. Create PVC `pvc-logs` in namespace `storage` requesting `500Mi` with storageClassName `manual`. It must bind to `pv-logs`.
3. Create Deployment `logger` (image `busybox:1.36`, `sh -c 'while true; do date >> /logs/out.log; sleep 5; done'`) mounting the PVC at `/logs`.
4. Write the PVC's **actual bound capacity** into `/opt/course/1/capacity.txt`.

<details><summary>Solution</summary>

```yaml
apiVersion: v1
kind: PersistentVolume
metadata: {name: pv-logs}
spec:
  capacity: {storage: 1Gi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath: {path: /mnt/data/logs}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: pvc-logs, namespace: storage}
spec:
  storageClassName: manual
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 500Mi}}
```

```bash
k create ns storage; k apply -f pv-pvc.yaml
k -n storage create deploy logger --image=busybox:1.36 $do -- sh -c 'while true; do date >> /logs/out.log; sleep 5; done' > logger.yaml
# add volumes + volumeMounts:
#   volumes: [{name: logs, persistentVolumeClaim: {claimName: pvc-logs}}]
#   volumeMounts: [{name: logs, mountPath: /logs}]
k apply -f logger.yaml
k -n storage get pvc pvc-logs -o jsonpath='{.status.capacity.storage}' > /opt/course/1/capacity.txt   # 1Gi (not 500Mi!)
```
</details>

---

## Q2 — Why is my PVC Pending? (5%)

PVC `data-claim` in namespace `storage` is stuck in `Pending`. A PV `pv-data` exists and is `Available`. Find and fix the reason(s) **without changing the PV**. Write the root cause(s) into `/opt/course/2/reason.txt`.

(The PV: `2Gi`, `ReadWriteMany`, storageClassName `nfs-slow`. The PVC: `3Gi`, `ReadWriteOnce`, storageClassName `nfs-fast`.)

<details><summary>Solution</summary>

Three mismatches: storageClassName differs, requested size > PV capacity, access mode doesn't match.

```bash
k -n storage get pvc data-claim -o yaml > pvc.yaml
# storageClassName: nfs-slow, accessModes: [ReadWriteMany], storage: 2Gi (or less)
k replace --force -f pvc.yaml      # most PVC spec fields are immutable
k -n storage get pvc data-claim    # Bound
```

`describe pvc` events: "storageclass.storage.k8s.io "nfs-fast" not found" etc. Access mode rule: the PV's `accessModes` list must contain **every** mode the PVC requests exactly — an RWX PV doesn't match a PVC requesting RWO (there's no mode "hierarchy").
</details>

---

## Q3 — StorageClass with WaitForFirstConsumer (5%)

1. Create StorageClass `local-wffc` with provisioner `kubernetes.io/no-provisioner`, `volumeBindingMode: WaitForFirstConsumer`, `reclaimPolicy: Delete`.
2. Make it the **default** StorageClass, and make sure the old default (`standard` / `local-path`) is **no longer** default.
3. Create PVC `wffc-pvc` (100Mi, RWO) without specifying a storageClassName. Explain into `/opt/course/3/why.txt` why it stays Pending even though nothing is wrong.

<details><summary>Solution</summary>

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-wffc
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
```

```bash
k get sc
k patch sc local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
k apply -f sc.yaml && k get sc          # only local-wffc (default)
k create -f wffc-pvc.yaml               # no storageClassName -> default is assigned
k get pvc wffc-pvc -o jsonpath='{.spec.storageClassName}'
echo "WaitForFirstConsumer: binding/provisioning is delayed until a Pod using the PVC is scheduled" > /opt/course/3/why.txt
```
</details>

---

## Q4 — Dynamic provisioning + volume expansion (5%)

A StorageClass `expandable` exists (dynamic provisioner, `allowVolumeExpansion: true`).

1. Create PVC `grow-me` (namespace `storage`, `1Gi`, RWO, class `expandable`) and Pod `grow-pod` (nginx) using it at `/usr/share/nginx/html`.
2. Expand the PVC to `2Gi` **without** deleting the pod or the PVC.
3. Try to shrink it back to `1Gi` and save the error to `/opt/course/4/shrink-error.txt`.

<details><summary>Solution</summary>

```bash
k -n storage patch pvc grow-me -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'
k -n storage get pvc grow-me -w        # CAPACITY 2Gi (some drivers show a FileSystemResizePending condition)
k -n storage patch pvc grow-me -p '{"spec":{"resources":{"requests":{"storage":"1Gi"}}}}' 2> /opt/course/4/shrink-error.txt
# ...spec.resources.requests.storage: Forbidden: field can not be less than previous value
```

If `allowVolumeExpansion` is false, expansion is rejected as well. Expansion doesn't work with hostPath/no-provisioner.
</details>

---

## Q5 — Reclaim policies in practice (4%)

1. Delete PVC `pvc-logs` from Q1 (scale `logger` to 0 first). What is the status of `pv-logs` now? Write it into `/opt/course/5/status.txt`.
2. Make `pv-logs` **reusable** by a new PVC `pvc-logs-2` (same spec) **without deleting the PV** and without losing the data on disk.

<details><summary>Solution</summary>

```bash
k -n storage scale deploy logger --replicas=0
k -n storage delete pvc pvc-logs
k get pv pv-logs -o jsonpath='{.status.phase}' > /opt/course/5/status.txt     # Released
k patch pv pv-logs --type=json -p '[{"op":"remove","path":"/spec/claimRef"}]'
k get pv pv-logs                         # Available
# create pvc-logs-2 -> Bound
```

`Retain` → the PV becomes `Released`; a new PVC can't bind until the old `claimRef` is removed. `Delete` → the PV and the backend storage are deleted.
</details>

---

## Q6 — Shared volume between containers & pod-level storage (3%)

Pod `shared` (namespace `default`) must have two containers:

- `writer` (`busybox:1.36`): writes `hello` to `/out/index.html` once then sleeps.
- `web` (`nginx:1.27-alpine`): serves `/usr/share/nginx/html` from the **same** volume.

The volume must use **memory** as its backing medium, size limit `64Mi`. Verify with `curl` from another pod.

<details><summary>Solution</summary>

```yaml
apiVersion: v1
kind: Pod
metadata: {name: shared, labels: {app: shared}}
spec:
  volumes:
  - name: html
    emptyDir: {medium: Memory, sizeLimit: 64Mi}
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "echo hello > /out/index.html && sleep 1d"]
    volumeMounts: [{name: html, mountPath: /out}]
  - name: web
    image: nginx:1.27-alpine
    volumeMounts: [{name: html, mountPath: /usr/share/nginx/html}]
```

```bash
k apply -f shared.yaml
k run t --rm -i --restart=Never --image=curlimages/curl -- curl -s $(k get pod shared -o jsonpath='{.status.podIP}')
```
</details>
