course_dir s13-fix
reset_ns s13-fix
C=/opt/course/s13-fix
mkdir -p $C/base $C/overlays/prod
cat > $C/base/deployment.yaml <<'YAML'
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
        image: nginx
        envFrom:
        - configMapRef:
            name: web-env
        resources:
          requests:
            cpu: 5m
            memory: 16Mi
YAML
cat > $C/base/service.yaml <<'YAML'
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
cat > $C/base/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- svc.yaml
YAML
cat > $C/overlays/prod/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: s13-fix
namePrefix: prod-
resources:
- ../../base
images:
- name: docker.io/library/nginx
  newTag: 1.27-alpine
replicas:
- name: web
  count: 3
configMapGenerator:
- name: web-env
  literals:
  - MODE=production
patches:
- path: limits.yaml
YAML
cat > $C/overlays/prod/limits.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  template:
    spec:
      containers:
      - name: web
        resources:
          limits:
            memory: 64Mi
YAML
( cd $C/base && sha256sum deployment.yaml service.yaml > /root/.s13-fix.sha )
chown -R candidate: /opt/course
