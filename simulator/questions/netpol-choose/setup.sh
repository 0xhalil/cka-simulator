course_dir netpol
reset_ns frontend backend
kubectl create ns netpol-test --dry-run=client -o yaml | kubectl apply -f - >/dev/null
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata: {name: frontend, namespace: frontend}
spec:
  replicas: 1
  selector: {matchLabels: {app: frontend}}
  template:
    metadata: {labels: {app: frontend, tier: web}}
    spec:
      containers: [{name: frontend, image: busybox:1.36, command: ["sleep", "1d"]}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: backend, namespace: backend}
spec:
  replicas: 1
  selector: {matchLabels: {app: backend}}
  template:
    metadata: {labels: {app: backend}}
    spec:
      containers: [{name: backend, image: nginx:1.27-alpine, ports: [{containerPort: 80}]}]
---
apiVersion: v1
kind: Service
metadata: {name: backend-svc, namespace: backend}
spec:
  selector: {app: backend}
  ports: [{port: 80, targetPort: 80}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny-ingress, namespace: backend}
spec:
  podSelector: {}
  policyTypes: [Ingress]
YAML
cat > /opt/course/netpol/netpol-1.yaml <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-ns
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
YAML
cat > /opt/course/netpol/netpol-2.yaml <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-pods
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
YAML
cat > /opt/course/netpol/netpol-3.yaml <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-or-app
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
YAML
chown -R candidate: /opt/course
wait_deploy frontend frontend; wait_deploy backend backend
