kubectl -n s02-deploy rollout history deploy payment
kubectl -n s02-deploy rollout undo deploy payment --to-revision=1
kubectl -n s02-deploy scale deploy payment --replicas=3
kubectl -n s02-deploy rollout status deploy payment --timeout=300s
kubectl -n s02-deploy create deploy checkout --image=httpd:2.4-alpine --replicas=3 --dry-run=client -o yaml \
 | sed 's/- image: httpd:2.4-alpine/- image: httpd:2.4-alpine\n        name: web/; /^        name: httpd$/d' > /tmp/checkout.yaml
cat <<'YAML' > /tmp/patch.yaml
spec:
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate: {maxSurge: 1, maxUnavailable: 0}
YAML
kubectl patch --local -f /tmp/checkout.yaml --type=merge --patch-file=/tmp/patch.yaml -o yaml | kubectl apply -f -
kubectl -n s02-deploy rollout status deploy checkout --timeout=300s
kubectl -n s02-deploy set image deploy/checkout web=httpd:2.4.68-alpine
kubectl -n s02-deploy rollout status deploy checkout --timeout=300s
kubectl -n s02-deploy get deploy checkout -o yaml | grep -A3 containers
