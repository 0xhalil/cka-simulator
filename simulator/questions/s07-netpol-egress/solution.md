Key points:
- `namespaceSelector` + `podSelector` in the same `from` item = **AND**. Separate items (`- namespaceSelector`, `- podSelector`) = **OR** → would also allow `role=frontend` pods inside `s07-np-app`.
- Adding `policyTypes: [Egress]` blocks **all** outgoing traffic → DNS (53 UDP+TCP) must be opened separately, otherwise even the name `db` can't be resolved.
- Because of `default-deny-ingress`, traffic from `api` to `db` must also be opened with a separate ingress rule (`db-policy`). (Egress on `api`, ingress on `db`: both are needed.)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny-ingress, namespace: s07-np-app}
spec:
  podSelector: {}
  policyTypes: [Ingress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: api-policy, namespace: s07-np-app}
spec:
  podSelector:
    matchLabels: {app: api}
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels: {kubernetes.io/metadata.name: s07-np-web}
      podSelector:
        matchLabels: {role: frontend}
    ports:
    - {protocol: TCP, port: 80}
  egress:
  - to:
    - podSelector:
        matchLabels: {app: db}
    ports:
    - {protocol: TCP, port: 6379}
  - ports:
    - {protocol: UDP, port: 53}
    - {protocol: TCP, port: 53}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: db-policy, namespace: s07-np-app}
spec:
  podSelector:
    matchLabels: {app: db}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels: {app: api}
    ports:
    - {protocol: TCP, port: 6379}
```
```bash
ssh cka-cp1
k apply -f np.yaml
k -n s07-np-web exec deploy/frontend -- wget -qO- -T3 api.s07-np-app
k -n s07-np-app exec deploy/api -- nc -zv -w3 db 6379       # open
k -n s07-np-app exec deploy/api -- nc -zv -w3 cache 6379    # timeout
```
