N=s14-relay
kubectl -n $N patch deploy relay --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":"http"}]'
kubectl -n $N patch svc relay-svc --type=json -p '[{"op":"replace","path":"/spec/selector","value":{"app":"relay","tier":"edge"}},{"op":"replace","path":"/spec/ports/0/targetPort","value":"http"}]'
kubectl -n $N rollout status deploy/relay --timeout=120s
