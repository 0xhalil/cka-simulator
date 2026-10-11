mkdir -p /opt/course/s13-trans/release
cat > /opt/course/s13-trans/release/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../base
namespace: s13-trans
namePrefix: blue-
nameSuffix: -v2
commonAnnotations:
  owner: team-blue
labels:
- pairs:
    release: r2
  includeSelectors: true
  includeTemplates: true
images:
- name: web-server
  newName: nginx
  newTag: 1.27-alpine
replicas:
- name: web
  count: 2
YAML
kubectl apply -k /opt/course/s13-trans/release
kubectl -n s13-trans rollout status deploy blue-web-v2 --timeout=120s
sleep 3
