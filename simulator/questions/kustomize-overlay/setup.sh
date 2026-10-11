course_dir kustomize
reset_ns shop-prod
mkdir -p /opt/course/kustomize/base
cat > /opt/course/kustomize/base/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: nginx
        ports:
        - containerPort: 80
YAML
cat > /opt/course/kustomize/base/service.yaml <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
  - port: 80
YAML
cat > /opt/course/kustomize/base/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
YAML
( cd /opt/course/kustomize/base && sha256sum * > /root/.kustomize-base.sha )
chown -R candidate: /opt/course
