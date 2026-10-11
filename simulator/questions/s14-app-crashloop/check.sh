U=$(cat /root/.s14/crashloop.uid 2>/dev/null)
stable() {  # stable <ns> <deploy> <replicas>: available, all Pods Ready and at most 1 restart and none during 15s
  kubectl -n $1 wait --for=condition=available deploy/$2 --timeout=30s || return 1
  local sel; sel=$(kubectl -n $1 get deploy $2 -o go-template='{{range $k,$v := .spec.selector.matchLabels}}{{$k}}={{$v}},{{end}}' | sed 's/,$//')
  local r1; r1=$(kubectl -n $1 get po -l "$sel" -o jsonpath='{range .items[*]}{.metadata.name}:{.status.containerStatuses[*].restartCount} {end}')
  sleep 15
  local r2; r2=$(kubectl -n $1 get po -l "$sel" -o jsonpath='{range .items[*]}{.metadata.name}:{.status.containerStatuses[*].restartCount} {end}')
  ! echo "$r2" | grep -Eq ':([2-9]|[1-9][0-9]+)( |$)' && [ "$r1" = "$r2" ] && [ "$(kubectl -n $1 get deploy $2 -o jsonpath='{.status.readyReplicas}')" = "$3" ]
}
N=s14-ledger
check "ledger-api is Ready and does not restart" 'stable $N ledger-api 1'
check "ledger-worker is Ready and does not restart" 'stable $N ledger-worker 1'
check "ledger-worker container sees LOG_LEVEL=debug" '[ "$(kubectl -n $N exec deploy/ledger-worker -- printenv LOG_LEVEL)" = debug ]'
check "ledger-cache is Ready and does not restart" 'stable $N ledger-cache 1'
check "ledger-cache warmed its full 24MiB in-memory cache" 'kubectl -n $N logs deploy/ledger-cache | grep -q "cache warmed: 25165824 bytes"'
guard "ledger-api still has a liveness probe" '[ -n "$(jp deploy ledger-api -n $N "{.spec.template.spec.containers[0].livenessProbe}")" ]'
guard "LOG_LEVEL still comes from ConfigMap ledger-config" '[ "$(jp deploy ledger-worker -n $N "{.spec.template.spec.containers[0].env[?(@.name==\"LOG_LEVEL\")].valueFrom.configMapKeyRef.name}")" = ledger-config ]'
guard "commands and images unchanged" '[ "$(kubectl -n $N get deploy ledger-api ledger-worker ledger-cache -o jsonpath="{range .items[*]}{.spec.template.spec.containers[0].image}|{.spec.template.spec.containers[0].command}|{end}" | md5sum | cut -c1-8)" = "$(cat /root/.s14/crashloop.cmd)" ]'
guard "Deployments not deleted/recreated" '[ "$(kubectl -n $N get deploy ledger-api ledger-worker ledger-cache -o jsonpath="{.items[*].metadata.uid}")" = "$U" ]'
