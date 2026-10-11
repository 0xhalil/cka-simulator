reset_ns web-app
TMP=$(mktemp -d)
openssl req -x509 -nodes -newkey rsa:2048 -days 365 -subj "/CN=*.web.k8s.local" \
  -addext "subjectAltName=DNS:*.web.k8s.local,DNS:ingress.web.k8s.local,DNS:gateway.web.k8s.local" \
  -keyout $TMP/tls.key -out $TMP/tls.crt 2>/dev/null
kubectl -n web-app create secret tls web-tls --cert=$TMP/tls.crt --key=$TMP/tls.key
rm -rf $TMP
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata: {name: web-content, namespace: web-app}
data:
  index.html: "web-app: served through the gateway\n"
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: web, namespace: web-app}
spec:
  replicas: 2
  selector: {matchLabels: {app: web}}
  template:
    metadata: {labels: {app: web}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        ports: [{containerPort: 80}]
        volumeMounts: [{name: c, mountPath: /usr/share/nginx/html}]
      volumes: [{name: c, configMap: {name: web-content}}]
---
apiVersion: v1
kind: Service
metadata: {name: web-svc, namespace: web-app}
spec:
  selector: {app: web}
  ports: [{port: 80, targetPort: 80}]
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: {name: web, namespace: web-app}
spec:
  ingressClassName: nginx
  tls:
  - hosts: [ingress.web.k8s.local]
    secretName: web-tls
  rules:
  - host: ingress.web.k8s.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service: {name: web-svc, port: {number: 80}}
YAML
