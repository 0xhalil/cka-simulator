O=/opt/course/s13-patch/overlays/staging
cat > $O/ledger-env.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ledger
spec:
  template:
    spec:
      containers:
      - name: ledger
        env:
        - name: LOG_LEVEL
          value: info
        - name: REGION
          value: eu-west
YAML
cat > $O/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: s13-patch
resources:
- ../../base
patches:
- target:
    kind: Deployment
    name: ledger
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 2
    - op: remove
      path: /spec/template/spec/containers/0/livenessProbe
- path: ledger-env.yaml
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
YAML
kubectl apply -k $O
for d in ledger audit frontend; do kubectl -n s13-patch rollout status deploy/$d --timeout=120s; done
