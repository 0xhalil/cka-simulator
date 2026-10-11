`--sort-by` sorts capacity as a **resource quantity**, not as a string (100Mi < 500Mi < 768Mi < 1Gi < 1536Mi < 2Gi). Trying to sort it yourself with the `sort` command (1536Mi vs 2Gi) gives wrong results. Only PVs with the `report=s15` label: `-l report=s15`.

```bash
ssh cka-cp1
k get pv -l report=s15 --sort-by=.spec.capacity.storage \
  -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,RECLAIM_POLICY:.spec.persistentVolumeReclaimPolicy > /opt/course/s15-pv/pvs.txt

# JSONPath filter expression: ?(@.field=="value")
k get pv -l report=s15 -o jsonpath='{.items[?(@.spec.persistentVolumeReclaimPolicy=="Retain")].metadata.name}' > /opt/course/s15-pv/retain.txt

# last element of the sorted list
k get pv -l report=s15 --sort-by=.spec.capacity.storage -o jsonpath='{.items[-1:].metadata.name}' > /opt/course/s15-pv/largest.txt
```
