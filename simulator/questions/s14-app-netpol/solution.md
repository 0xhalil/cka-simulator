Three independent errors (they appear in sequence):

1. **DNS name**: `PAYMENTS_URL=http://payments:8080/` — the short name only resolves in the **same namespace**. The Service is in `s14-pay-api` → `http://payments.s14-pay-api:8080/` (or the FQDN `payments.s14-pay-api.svc.cluster.local`).
2. **Egress**: `s14-pay-web` has `default-deny-egress`, `allow-dns` only allows 53 → an egress policy from checkout to payments is needed.
3. **Ingress port**: `allow-checkout` allows port **8080**; but NetworkPolicy applies to the **pod (targetPort) port**, not the Service port (after kube-proxy DNAT). httpd listens on 80 → new policy on port 80. The same trap applies to the egress policy: 8080 won't work.

Modifying existing policies is forbidden → write additional policies (policies are additive/OR).

```bash
k -n s14-pay-web exec deploy/checkout -- cat /tmp/status     # bad address 'payments'
k -n s14-pay-web set env deploy/checkout PAYMENTS_URL=http://payments.s14-pay-api:8080/
k -n s14-pay-web exec deploy/checkout -- cat /tmp/status     # download timed out
k get netpol -A | grep s14-pay; k -n s14-pay-api get svc payments -o yaml   # targetPort: http -> 80
```
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-checkout-http, namespace: s14-pay-api}
spec:
  podSelector: {matchLabels: {app: payments}}
  policyTypes: [Ingress]
  ingress:
  - from:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: s14-pay-web}}
      podSelector: {matchLabels: {app: checkout}}     # same item = AND
    ports: [{protocol: TCP, port: 80}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: checkout-to-payments, namespace: s14-pay-web}
spec:
  podSelector: {matchLabels: {app: checkout}}
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: s14-pay-api}}
      podSelector: {matchLabels: {app: payments}}
    ports: [{protocol: TCP, port: 80}]
```
```bash
k -n s14-pay-web get po -w        # checkout 1/1 Ready
```
