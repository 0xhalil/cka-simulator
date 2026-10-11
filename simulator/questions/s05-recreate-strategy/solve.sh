kubectl -n s05-recreate patch deploy ledger --type=json -p '[{"op":"remove","path":"/spec/strategy/rollingUpdate"},{"op":"replace","path":"/spec/strategy/type","value":"Recreate"}]'
kubectl -n s05-recreate set image deploy/ledger app=nginx:1.28-alpine
kubectl -n s05-recreate annotate deploy ledger kubernetes.io/change-cause="upgrade app to 1.28" --overwrite
kubectl -n s05-recreate rollout status deploy ledger --timeout=180s
kubectl -n s05-recreate get deploy ledger -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}' > /opt/course/s05-recreate/revision.txt
