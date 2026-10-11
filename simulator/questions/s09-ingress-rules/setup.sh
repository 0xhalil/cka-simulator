course_dir s09-ingress
reset_ns s09-shop
openssl req -x509 -nodes -newkey rsa:2048 -days 365 -subj "/CN=shop.s09.local" \
  -addext "subjectAltName=DNS:shop.s09.local" \
  -keyout /opt/course/s09-ingress/shop.key -out /opt/course/s09-ingress/shop.crt 2>/dev/null
chown -R candidate: /opt/course/s09-ingress
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: shop, namespace: s09-shop}
spec:
  replicas: 1
  selector: {matchLabels: {app: shop}}
  template:
    metadata: {labels: {app: shop}}
    spec:
      containers:
      - name: web
        image: nginx:1.27-alpine
        resources: {requests: {cpu: 5m, memory: 16Mi}}
---
apiVersion: v1
kind: Service
metadata: {name: shop-ui, namespace: s09-shop}
spec:
  selector: {app: shop}
  ports: [{name: http, port: 80, targetPort: 80}]
---
apiVersion: v1
kind: Service
metadata: {name: shop-pay, namespace: s09-shop}
spec:
  selector: {app: shop}
  ports: [{name: http, port: 8282, targetPort: 80}]
---
apiVersion: v1
kind: Service
metadata: {name: shop-default, namespace: s09-shop}
spec:
  selector: {app: shop}
  ports: [{name: http, port: 80, targetPort: 80}]
YAML
