```yaml
# /opt/course/kustomize/overlays/prod/kustomization.yaml
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
```
```bash
k kustomize /opt/course/kustomize/overlays/prod
k apply -k /opt/course/kustomize/overlays/prod
```
