reset_ns s14-gallery
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: ConfigMap
metadata: {name: gallery-config, namespace: s14-gallery}
data:
  default.conf: |
    server {
      listen 8080;
      root /etc/nginx/conf.d;
      location = / { try_files /index.html =404; }
    }
  index.html: |
    <html><body><h1>GALLERY-OK</h1><p>42 pictures</p></body></html>
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: gallery, namespace: s14-gallery}
spec:
  replicas: 2
  selector: {matchLabels: {app: gallery}}
  template:
    metadata: {labels: {app: gallery}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpne
        ports: [{containerPort: 8080}]
        resources: {requests: {cpu: 5m, memory: 16Mi}, limits: {memory: 64Mi}}
        volumeMounts: [{name: conf, mountPath: /etc/nginx/conf.d}]
      volumes:
      - name: conf
        configMap: {name: gallery-conf}
---
apiVersion: v1
kind: Service
metadata: {name: gallery, namespace: s14-gallery}
spec:
  selector: {app: gallery}
  ports: [{port: 80, targetPort: 80}]
YAML
mkdir -p /root/.s14 && kubectl -n s14-gallery get deploy/gallery svc/gallery -o jsonpath='{.items[*].metadata.uid}' > /root/.s14/gallery.uid
