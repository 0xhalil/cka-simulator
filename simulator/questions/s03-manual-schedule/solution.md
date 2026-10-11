If the scheduler named in `schedulerName` doesn't exist, the Pod stays `Pending` forever. The scheduler's only job is to write `spec.nodeName` into the Pod — we can do that by hand too.

**1. manual-web** — `nodeName` **cannot be changed** afterwards (immutable), the Pod must be recreated:
```bash
ssh cka-cp1
k -n s03-manual get pod manual-web -o yaml > web.yaml
# add under spec:  nodeName: cka-w1    (status/uid/resourceVersion can be deleted)
k -n s03-manual replace --force -f web.yaml
```
Once `nodeName` is set, the scheduler is bypassed entirely; the `schedulerName` field no longer matters, no need to change it.

**2. manual-api** — assignment without deleting the Pod: POST a **Binding** object, just like kube-scheduler does (the method from the lecture):
```yaml
apiVersion: v1
kind: Binding
metadata: {name: manual-api, namespace: s03-manual}
target: {apiVersion: v1, kind: Node, name: cka-w1}
```
```bash
k create -f binding.yaml
# alternative: k create --raw /api/v1/namespaces/s03-manual/pods/manual-api/binding -f binding.json
k -n s03-manual get pod -o wide
```
Trap: trying to add `nodeName` to a running Pod with `kubectl edit` is rejected ("spec: Forbidden: pod updates may not change fields...").
