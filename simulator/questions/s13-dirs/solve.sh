K=/opt/course/s13-dirs/k8s
for d in api cache web; do printf 'apiVersion: kustomize.config.k8s.io/v1beta1\nkind: Kustomization\nresources:\n- deployment.yaml\n- service.yaml\n' > $K/$d/kustomization.yaml; done
cat > $K/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: s13-dirs
labels:
- pairs:
    app.kubernetes.io/part-of: bookshop
resources:
- api
- cache
- web
YAML
kubectl apply -k $K
