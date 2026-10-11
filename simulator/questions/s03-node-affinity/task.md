The Deployment `ssd-cache` in namespace `s03-affinity` cannot be scheduled. It still uses an outdated `nodeSelector`.

1. Label node `cka-w1` with `s03.cka.local/disktype=ssd`. Do **not** label `cka-cp1`.
2. Replace the `nodeSelector` of the Deployment with **node affinity**:
   - Pods **must** only be scheduled on nodes where label `s03.cka.local/disktype` has the value `ssd` **or** `nvme`.
   - Pods should **preferably** (weight `75`) be scheduled on nodes with label `s03.cka.local/zone=zone-a`. No node carries this label at the moment — the Pods must be scheduled anyway.
3. Ensure both replicas are running on `cka-w1`.

Do not taint or untaint any node.
