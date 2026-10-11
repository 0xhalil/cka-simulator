cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: LimitRange
metadata: {name: container-limits, namespace: s03-quota}
spec:
  limits:
  - type: Container
    default: {cpu: 200m, memory: 128Mi}
    defaultRequest: {cpu: 50m, memory: 32Mi}
    max: {cpu: 500m, memory: 256Mi}
YAML
kubectl -n s03-quota create quota team-quota --hard=requests.cpu=500m,requests.memory=512Mi,limits.cpu=1,limits.memory=1Gi,pods=6
kubectl -n s03-quota rollout restart deploy api
kubectl -n s03-quota rollout status deploy api --timeout=120s
kubectl -n s03-quota run oversized --image=nginx:1.27-alpine --overrides='{"spec":{"containers":[{"name":"oversized","image":"nginx:1.27-alpine","resources":{"limits":{"cpu":"1"}}}]}}' 2> /opt/course/s03-quota/oversized.txt
cat /opt/course/s03-quota/oversized.txt
