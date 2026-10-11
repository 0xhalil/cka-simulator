- `netpol-1`: allows **all** pods in the `frontend` namespace → too broad.
- `netpol-3`: two separate `from` items = **OR** → all pods in the `frontend` ns **and** pods labeled `app=frontend` in the `backend` ns → too broad.
- `netpol-2`: `namespaceSelector` + `podSelector` in the same item = **AND**, only TCP/80 → correct.

```bash
ssh cka-cp1
k apply -f /opt/course/netpol/netpol-2.yaml
k -n frontend exec deploy/frontend -- wget -qO- -T3 backend-svc.backend
```
