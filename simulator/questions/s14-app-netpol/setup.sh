reset_ns s14-pay-web s14-pay-api
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata: {name: payments-page, namespace: s14-pay-api}
data:
  index.html: "PAYMENT-OK status=accepted\n"
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: payments, namespace: s14-pay-api}
spec:
  replicas: 1
  selector: {matchLabels: {app: payments}}
  template:
    metadata: {labels: {app: payments}}
    spec:
      containers:
      - name: api
        image: httpd:2.4-alpine
        ports: [{name: http, containerPort: 80}]
        resources: {requests: {cpu: 10m, memory: 16Mi}, limits: {memory: 64Mi}}
        volumeMounts: [{name: page, mountPath: /usr/local/apache2/htdocs}]
      volumes: [{name: page, configMap: {name: payments-page}}]
---
apiVersion: v1
kind: Service
metadata: {name: payments, namespace: s14-pay-api}
spec:
  selector: {app: payments}
  ports: [{port: 8080, targetPort: http}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny-ingress, namespace: s14-pay-api}
spec:
  podSelector: {}
  policyTypes: [Ingress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-checkout, namespace: s14-pay-api}
spec:
  podSelector: {matchLabels: {app: payments}}
  policyTypes: [Ingress]
  ingress:
  - from:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: s14-pay-web}}
      podSelector: {matchLabels: {app: checkout}}
    ports:
    - {protocol: TCP, port: 8080}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny-egress, namespace: s14-pay-web}
spec:
  podSelector: {}
  policyTypes: [Egress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-dns, namespace: s14-pay-web}
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}}
    ports:
    - {protocol: UDP, port: 53}
    - {protocol: TCP, port: 53}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: checkout, namespace: s14-pay-web}
spec:
  replicas: 1
  selector: {matchLabels: {app: checkout}}
  template:
    metadata: {labels: {app: checkout}}
    spec:
      containers:
      - name: checkout
        image: busybox:1.36
        env:
        - {name: PAYMENTS_URL, value: "http://payments:8080/"}
        command: ["sh", "-c", "while true; do if wget -qO- -T 3 \"$PAYMENTS_URL\" > /tmp/resp 2>/tmp/err; then cp /tmp/resp /tmp/status; else echo \"FAILED: $(cat /tmp/err)\" > /tmp/status; fi; sleep 3; done"]
        readinessProbe:
          exec: {command: ["grep", "-q", "PAYMENT-OK", "/tmp/status"]}
          periodSeconds: 3
        resources: {requests: {cpu: 5m, memory: 8Mi}, limits: {memory: 32Mi}}
YAML
mkdir -p /root/.s14
kubectl get netpol -n s14-pay-api default-deny-ingress allow-checkout -o jsonpath='{range .items[*]}{.metadata.uid}{end}' > /root/.s14/netpol.uid
kubectl get netpol -n s14-pay-web default-deny-egress allow-dns -o jsonpath='{range .items[*]}{.metadata.uid}{end}' >> /root/.s14/netpol.uid
kubectl -n s14-pay-api get deploy/payments svc/payments -o jsonpath='{range .items[*]}{.metadata.generation}{.spec.ports}{end}' > /root/.s14/netpol.api
wait_deploy s14-pay-api payments 120s
