course_dir s13-trans
reset_ns s13-trans
B=/opt/course/s13-trans/base
mkdir -p $B
cat > $B/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: web-server
        envFrom:
        - configMapRef:
            name: web-config
        resources:
          requests:
            cpu: 5m
            memory: 16Mi
YAML
cat > $B/service.yaml <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
  - port: 80
YAML
cat > $B/configmap.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-config
data:
  THEME: blue
YAML
cat > $B/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
- configmap.yaml
YAML
( cd $B && sha256sum * > /root/.s13-trans.sha )
chown -R candidate: /opt/course
