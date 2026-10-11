U=$(cat /root/.s14/twotier.uid 2>/dev/null)
probe() {  # probe <url> <expect> -> 0 if the url returns the expected text
  local n="probe-$RANDOM"
  kubectl -n s14-shop run "$n" --image=busybox:1.36 --restart=Never --labels=s14-probe=1 --command -- \
    sh -c "for i in 1 2 3 4; do wget -qO- -T 4 '$1' 2>/dev/null | grep -q '$2' && exit 0; sleep 2; done; exit 1" >/dev/null 2>&1
  kubectl -n s14-shop wait --for=jsonpath='{.status.phase}'=Succeeded pod/"$n" --timeout=45s >/dev/null 2>&1; local rc=$?
  kubectl -n s14-shop delete pod "$n" --now >/dev/null 2>&1; return $rc
}
DBURL="http://$(jp deploy web -n s14-shop '{.spec.template.spec.containers[0].env[?(@.name=="DB_HOST")].value}'):$(jp deploy web -n s14-shop '{.spec.template.spec.containers[0].env[?(@.name=="DB_PORT")].value}')/"
check "catalog DB answers on the host/port the web tier is configured with (DB_HOST/DB_PORT)" 'probe "$DBURL" CATALOG-DB-OK'
stable() {  # stable <ns> <deploy> <replicas>: available, all Pods Ready and at most 1 restart and none during 15s
  kubectl -n $1 wait --for=condition=available deploy/$2 --timeout=30s || return 1
  local sel; sel=$(kubectl -n $1 get deploy $2 -o go-template='{{range $k,$v := .spec.selector.matchLabels}}{{$k}}={{$v}},{{end}}' | sed 's/,$//')
  local r1; r1=$(kubectl -n $1 get po -l "$sel" -o jsonpath='{range .items[*]}{.metadata.name}:{.status.containerStatuses[*].restartCount} {end}')
  sleep 15
  local r2; r2=$(kubectl -n $1 get po -l "$sel" -o jsonpath='{range .items[*]}{.metadata.name}:{.status.containerStatuses[*].restartCount} {end}')
  ! echo "$r2" | grep -Eq ':([2-9]|[1-9][0-9]+)( |$)' && [ "$r1" = "$r2" ] && [ "$(kubectl -n $1 get deploy $2 -o jsonpath='{.status.readyReplicas}')" = "$3" ]
}
check "Deployment web is available, its Pod Ready and not restarting" 'stable s14-shop web 1'
check "Service web-service has a ready endpoint" '[ "$(kubectl -n s14-shop get endpointslice -l kubernetes.io/service-name=web-service -o jsonpath="{range .items[*].endpoints[*]}{.conditions.ready}{\"\n\"}{end}" | grep -c true)" -ge 1 ]'
check "catalog page is served on <nodeIP>:31401 for every node" 'for ip in $(kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type==\"InternalIP\")].address}"); do ok=; for t in 1 2 3 4 5 6; do curl -s --max-time 4 http://$ip:31401/ | grep -q CATALOG-DB-OK && { ok=1; break; }; sleep 3; done; [ -n "$ok" ] || exit 1; done'
guard "Deployments web and catalog were not deleted/recreated" '[ "$(kubectl -n s14-shop get deploy web catalog -o jsonpath="{.items[*].metadata.uid}")" = "$U" ]'
guard "container images unchanged" '[ "$(jp deploy web -n s14-shop "{.spec.template.spec.containers[0].image}") $(jp deploy catalog -n s14-shop "{.spec.template.spec.containers[0].image}")" = "nginx:1.27-alpine httpd:2.4-alpine" ]'
guard "catalog content unchanged" 'jp cm catalog-data -n s14-shop "{.data.index\.html}" | grep -q "12 products in stock"'
