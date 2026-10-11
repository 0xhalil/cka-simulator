course_dir s13-comp
reset_ns s13-comp-dev s13-comp-premium
C=/opt/course/s13-comp
mkdir -p $C/base $C/overlays/dev $C/overlays/premium $C/overlays/selfhosted $C/components/external-db
cat > $C/base/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: shop
        image: nginx:1.27-alpine
        env:
        - name: SHOP_MODE
          value: standard
        resources:
          requests:
            cpu: 5m
            memory: 16Mi
YAML
cat > $C/base/service.yaml <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: shop
spec:
  selector:
    app: shop
  ports:
  - port: 80
YAML
printf 'apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n- deployment.yaml\n- service.yaml\n' > $C/base/kustomization.yaml
cat > $C/components/external-db/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
patches:
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: shop
    spec:
      template:
        spec:
          containers:
          - name: shop
            env:
            - name: DB_HOST
              value: postgres.db.example.com
YAML
for o in dev premium; do cat > $C/overlays/$o/kustomization.yaml <<YAML
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: s13-comp-$o
resources:
- ../../base
components:
- ../../components/external-db
YAML
done
cat > $C/overlays/selfhosted/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: s13-comp-selfhosted
resources:
- ../../base
YAML
( cd $C/base && sha256sum * > /root/.s13-comp.sha )
chown -R candidate: /opt/course
