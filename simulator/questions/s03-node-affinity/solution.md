```bash
ssh cka-cp1
k label node cka-w1 s03.cka.local/disktype=ssd
k -n s03-affinity edit deploy ssd-cache
```
```yaml
    spec:
      # nodeSelector: {disk: ssd}    <- DELETE
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - {key: s03.cka.local/disktype, operator: In, values: [ssd, nvme]}
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 75
            preference:
              matchExpressions:
              - {key: s03.cka.local/zone, operator: In, values: [zone-a]}
```
```bash
k -n s03-affinity rollout status deploy ssd-cache
k -n s03-affinity get pod -o wide
```
Notes: if both `nodeSelector` and `nodeAffinity` remain, **both** must be satisfied (AND) → still Pending. "ssd **or** nvme" is a single `In` expression; writing two separate matchExpressions would be AND. The pod is scheduled even if the preferred rule isn't satisfied. Doc: "Assign Pods to Nodes using Node Affinity".
