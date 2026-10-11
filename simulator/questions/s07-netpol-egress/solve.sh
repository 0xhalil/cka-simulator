cat <<'YAML' | kubectl apply -f -
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
  podSelector: {matchLabels: {app: api}}
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: s07-np-web}}
      podSelector: {matchLabels: {role: frontend}}
    ports: [{protocol: TCP, port: 80}]
  egress:
  - to:
    - podSelector: {matchLabels: {app: db}}
    ports: [{protocol: TCP, port: 6379}]
  - ports: [{protocol: UDP, port: 53}, {protocol: TCP, port: 53}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: db-policy, namespace: s07-np-app}
spec:
  podSelector: {matchLabels: {app: db}}
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: api}}
    ports: [{protocol: TCP, port: 6379}]
YAML
sleep 3
