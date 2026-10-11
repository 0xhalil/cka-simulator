- Subresources are listed separately: `pods/log`, `pods/exec` (the verb for exec is **create**; older kubectl versions also use `get`).
- `resourceNames` only works for requests by name (`get/update/patch/exec`), not for `list`/`create` (new object) → don't grant `list` for the ConfigMap.
- The subject must be a **Group** (`--group=s07-support`).

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: support, namespace: s07-apps}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","list"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["pods/exec"]
  resourceNames: ["debug-shell"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["app-config"]
  verbs: ["get","update","patch"]
```
```bash
ssh cka-cp1
k apply -f role.yaml
k -n s07-apps create rolebinding support --role=support --group=s07-support
k -n s07-apps logs app --as=tom --as-group=s07-support > /opt/course/s07-rbac/app.log
k auth can-i create pods/payments --subresource=exec -n s07-apps --as=tom --as-group=s07-support \
  > /opt/course/s07-rbac/exec-payments.txt          # no
k auth can-i create pods/debug-shell --subresource=exec -n s07-apps --as=tom --as-group=s07-support   # yes
```
