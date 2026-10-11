N=s14-ledger
kubectl -n $N patch deploy ledger-api --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/port","value":80}]'
kubectl -n $N patch deploy ledger-worker --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/env/0/valueFrom/configMapKeyRef/key","value":"log_level"}]'
kubectl -n $N set resources deploy ledger-cache --limits=memory=64Mi
for d in ledger-api ledger-worker ledger-cache; do kubectl -n $N rollout status deploy/$d --timeout=120s; done
