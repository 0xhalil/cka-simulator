C=/opt/course/s13-comp
sed -i 's#^apiVersion: kustomize.config.k8s.io/v1beta1#apiVersion: kustomize.config.k8s.io/v1alpha1#; s#^kind: Kustomization#kind: Component#' $C/components/external-db/kustomization.yaml
mkdir -p $C/components/caching
cat > $C/components/caching/redis.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis-cache
  template:
    metadata:
      labels:
        app: redis-cache
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        resources:
          requests:
            cpu: 5m
            memory: 16Mi
---
apiVersion: v1
kind: Service
metadata:
  name: redis-cache
spec:
  selector:
    app: redis-cache
  ports:
  - port: 6379
YAML
cat > $C/components/caching/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
- redis.yaml
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
            - name: CACHE_HOST
              value: redis-cache
YAML
echo '- ../../components/caching' >> $C/overlays/premium/kustomization.yaml
printf 'components:\n- ../../components/caching\n' >> $C/overlays/selfhosted/kustomization.yaml
kubectl apply -k $C/overlays/dev
kubectl apply -k $C/overlays/premium
kubectl -n s13-comp-premium rollout status deploy/redis-cache --timeout=120s
