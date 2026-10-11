Method (the 4 steps from the course): find the command → inspect the structure with `-o json` → build the JSONPath query → use it with `-o jsonpath='{...}'`.

```bash
ssh cka-cp1
k get nodes -o json | less

# 1) range loop: fields per item, \t and \n
k get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.capacity.cpu}{"\t"}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' > /opt/course/s15-nodes/nodes.txt

# 2) custom-columns: queries are written WITHOUT .items, per item
k get nodes -o custom-columns=NODE:.metadata.name,TAINT_KEY:.spec.taints[*].key,TAINT_EFFECT:.spec.taints[*].effect > /opt/course/s15-nodes/taints.txt

# 3) all images, unique and sorted
k -n kube-system get pod -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u > /opt/course/s15-nodes/images.txt
```
Trap: taking the InternalIP with `addresses[0]` isn't always correct — use the filter `[?(@.type=="InternalIP")]`. A node without taints shows `<none>` in custom-columns.
