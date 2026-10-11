reset_ns s14-shop
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata: {name: catalog-data, namespace: s14-shop}
data:
  index.html: |
    <html><body style="background:#2e7d32;color:#fff"><h1>CATALOG-DB-OK</h1><p>12 products in stock</p></body></html>
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: catalog, namespace: s14-shop, labels: {app: catalog, tier: db}}
spec:
  replicas: 1
  selector: {matchLabels: {app: catalog}}
  template:
    metadata: {labels: {app: catalog, tier: db}}
    spec:
      containers:
      - name: catalog
        image: httpd:2.4-alpine
        ports: [{containerPort: 80}]
        resources: {requests: {cpu: 10m, memory: 16Mi}, limits: {memory: 64Mi}}
        volumeMounts: [{name: data, mountPath: /usr/local/apache2/htdocs}]
      volumes: [{name: data, configMap: {name: catalog-data}}]
---
apiVersion: v1
kind: Service
metadata: {name: catalog, namespace: s14-shop}
spec:
  selector: {app: catalog, tier: db}
  ports: [{name: db, port: 80, targetPort: 8080}]
---
apiVersion: v1
kind: ConfigMap
metadata: {name: web-proxy, namespace: s14-shop}
data:
  default.conf.template: |
    server {
      listen 8080;
      location /healthz { return 200 "ok\n"; }
      location / {
        proxy_pass http://${DB_HOST}:${DB_PORT}/;
        proxy_connect_timeout 3s;
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: web, namespace: s14-shop, labels: {app: web, tier: frontend}}
spec:
  replicas: 1
  selector: {matchLabels: {app: web}}
  template:
    metadata: {labels: {app: web, tier: frontend}}
    spec:
      containers:
      - name: web
        image: nginx:1.27-alpine
        env:
        - {name: DB_HOST, value: catalog-service}
        - {name: DB_PORT, value: "80"}
        ports: [{containerPort: 8080}]
        readinessProbe: {httpGet: {path: /healthz, port: 8080}, periodSeconds: 5}
        resources: {requests: {cpu: 10m, memory: 16Mi}, limits: {memory: 64Mi}}
        volumeMounts: [{name: tpl, mountPath: /etc/nginx/templates}]
      volumes: [{name: tpl, configMap: {name: web-proxy}}]
---
apiVersion: v1
kind: Service
metadata: {name: web-service, namespace: s14-shop}
spec:
  type: NodePort
  selector: {app: web-frontend}
  ports: [{port: 8080, targetPort: 8080, nodePort: 31401}]
YAML
mkdir -p /root/.s14 && kubectl -n s14-shop get deploy web catalog -o jsonpath='{.items[*].metadata.uid}' > /root/.s14/twotier.uid
wait_deploy s14-shop catalog 120s
