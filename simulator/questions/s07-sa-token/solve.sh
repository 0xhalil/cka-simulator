D=/opt/course/s07-sa
kubectl -n s07-sa create sa reporter
kubectl -n s07-sa create role reporter --verb=get,list --resource=pods
kubectl -n s07-sa create rolebinding reporter --role=reporter --serviceaccount=s07-sa:reporter
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: reporter-token
  namespace: s07-sa
  annotations: {kubernetes.io/service-account.name: reporter}
type: kubernetes.io/service-account-token
YAML
for i in $(seq 20); do T=$(kubectl -n s07-sa get secret reporter-token -o jsonpath='{.data.token}'); [ -n "$T" ] && break; sleep 1; done
echo "$T" | base64 -d > $D/reporter.token
kubectl -n s07-sa create token reporter --duration=2h > $D/reporter-2h.token
kubectl -n s07-sa create secret docker-registry regcred --docker-server=registry.s07.internal:5000 --docker-username=scanner --docker-password=Sc4nner-Pass
kubectl -n s07-sa patch sa reporter -p '{"imagePullSecrets":[{"name":"regcred"}]}'
kubectl -n s07-sa set serviceaccount deploy scanner reporter
kubectl -n s07-sa patch sa batch-runner -p '{"automountServiceAccountToken":false}'
kubectl -n s07-sa rollout restart deploy batch
kubectl -n s07-sa rollout status deploy scanner --timeout=90s
kubectl -n s07-sa rollout status deploy batch --timeout=90s
chown -R candidate: $D
