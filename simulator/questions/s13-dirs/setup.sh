course_dir s13-dirs
reset_ns s13-dirs
K=/opt/course/s13-dirs/k8s
mkdir -p $K/api $K/cache $K/web
mk() {  # dir name image port
cat > $K/$1/deployment.yaml <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $2
  template:
    metadata:
      labels:
        app: $2
    spec:
      containers:
      - name: $2
        image: $3
        ports:
        - containerPort: $4
        resources:
          requests:
            cpu: 5m
            memory: 16Mi
YAML
cat > $K/$1/service.yaml <<YAML
apiVersion: v1
kind: Service
metadata:
  name: $2
spec:
  selector:
    app: $2
  ports:
  - port: $4
YAML
}
mk api books-api httpd:2.4-alpine 80
mk cache books-cache redis:7-alpine 6379
mk web books-web nginx:1.27-alpine 80
cat > $K/cache/legacy-configmap.yaml <<'YAML'
# OLD memcached settings - kept for reference only, do not deploy
apiVersion: v1
kind: ConfigMap
metadata:
  name: books-cache-legacy
data:
  MEMCACHED_HOST: memcached.legacy.svc
YAML
( cd $K && sha256sum */*.yaml > /root/.s13-dirs.sha )
chown -R candidate: /opt/course
