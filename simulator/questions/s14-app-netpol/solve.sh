kubectl -n s14-pay-web set env deploy/checkout PAYMENTS_URL=http://payments.s14-pay-api.svc.cluster.local:8080/
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-checkout-http, namespace: s14-pay-api}
spec:
  podSelector: {matchLabels: {app: payments}}
  policyTypes: [Ingress]
  ingress:
  - from:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: s14-pay-web}}
      podSelector: {matchLabels: {app: checkout}}
    ports:
    - {protocol: TCP, port: 80}
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
    ports:
    - {protocol: TCP, port: 80}
YAML
kubectl -n s14-pay-web rollout status deploy/checkout --timeout=120s
