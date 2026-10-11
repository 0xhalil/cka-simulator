mkdir -p /opt/course/kustomize/overlays/prod
cat > /opt/course/kustomize/overlays/prod/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
namespace: shop-prod
labels:
- pairs: {env: prod}
replicas:
- {name: api, count: 3}
images:
- {name: nginx, newTag: 1.27-alpine}
configMapGenerator:
- name: api-config
  literals: [LOG_LEVEL=warn]
patches:
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata: {name: api}
    spec:
      template:
        spec:
          containers:
          - name: api
            envFrom:
            - configMapRef: {name: api-config}
YAML
kubectl apply -k /opt/course/kustomize/overlays/prod
kubectl -n shop-prod rollout status deploy api
