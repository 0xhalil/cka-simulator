```yaml
# /opt/course/s13-patch/overlays/staging/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: s13-patch
resources:
- ../../base
patches:
# 1) JSON6902 inline: target + op list
- target:
    kind: Deployment
    name: ledger
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 2
    - op: remove
      path: /spec/template/spec/containers/0/livenessProbe
# 2) strategic merge, separate file
- path: ledger-env.yaml
# 3) targeting by label selector (metadata.name is irrelevant, target decides)
- target:
    kind: Deployment
    labelSelector: tier=backend
  patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: any
    spec:
      template:
        metadata:
          annotations:
            backup.s13/enabled: "true"
```
```yaml
# /opt/course/s13-patch/overlays/staging/ledger-env.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ledger
spec:
  template:
    spec:
      containers:
      - name: ledger          # list items are merged by "name" (merge key)
        env:
        - name: LOG_LEVEL
          value: info
        - name: REGION
          value: eu-west
```
```bash
ssh cka-cp1
k kustomize /opt/course/s13-patch/overlays/staging
k apply -k /opt/course/s13-patch/overlays/staging
k -n s13-patch get deploy
```
Traps: in JSON6902 `containers` is a list → addressed by index (`/containers/0/...`); in strategic merge it's merged by `name` and other fields are preserved. The annotation value must be a string (`"true"`).
