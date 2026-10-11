G="-n s09-gw-infra gateway.gateway.networking.k8s.io shared-gw"; R="-n s09-gw-team httproute.gateway.networking.k8s.io portal-route"
RG="-n s09-gw-backend referencegrant.gateway.networking.k8s.io allow-portal-team"
NP=$(kubectl -n s09-gw-infra get svc -l gateway.networking.k8s.io/gateway-name=shared-gw -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}' 2>/dev/null)
IP=$(jp node cka-w1 '{.status.addresses[?(@.type=="InternalIP")].address}')
req() { curl -s --max-time 4 -H "Host: portal.s09.local" "$@"; }
retry() { for t in 1 2 3 4 5 6; do eval "$1" && return 0; sleep 5; done; return 1; }
guard "Gateway listener unchanged (http/HTTP/80/portal.s09.local, class nginx)" '[ "$(jp $G "{.spec.gatewayClassName}|{range .spec.listeners[*]}{.name}:{.protocol}:{.port}:{.hostname};{end}")" = "nginx|http:HTTP:80:portal.s09.local;" ]'
check "namespace s09-gw-team labelled gateway-access=true" '[ "$(jp ns s09-gw-team "{.metadata.labels.gateway-access}")" = true ]'
check "listener http allows routes only from namespaces with gateway-access=true" 'kubectl get $G -o json | jq -e ".spec.listeners[0].allowedRoutes.namespaces as \$n | \$n.from == \"Selector\" and ((\$n.selector.matchLabels[\"gateway-access\"] == \"true\" and ((\$n.selector.matchExpressions // []) | length == 0)) or (\$n.selector.matchExpressions == [{\"key\":\"gateway-access\",\"operator\":\"In\",\"values\":[\"true\"]}] and ((\$n.selector.matchLabels // {}) | length == 0)))"'
check "ReferenceGrant allow-portal-team: from HTTPRoute in s09-gw-team to Services" 'kubectl get $RG -o json | jq -e "(.spec.from == [{\"group\":\"gateway.networking.k8s.io\",\"kind\":\"HTTPRoute\",\"namespace\":\"s09-gw-team\"}]) and ([.spec.to[] | select(.group == \"\" and .kind == \"Service\")] | length == 1) and (.spec.to | length == 1)"'
check "HTTPRoute portal-route Accepted and ResolvedRefs on shared-gw" 'retry "[ \"\$(jp $R \"{.spec.hostnames[*]}|{.status.parents[?(@.parentRef.name==\\\"shared-gw\\\")].conditions[?(@.type==\\\"Accepted\\\")].status}{.status.parents[?(@.parentRef.name==\\\"shared-gw\\\")].conditions[?(@.type==\\\"ResolvedRefs\\\")].status}\")\" = \"portal.s09.local|TrueTrue\" ]"'
check "GET /api/ returns portal-api through the Gateway" 'retry "req http://$IP:$NP/api/ | grep -q \"portal-api v1\""'
check "GET /legacy/x answers 301 with Location .../api/x" 'retry "req -o /dev/null -w \"%{http_code} %{redirect_url}\" http://$IP:$NP/legacy/x | grep -Eq \"^301 http://portal\.s09\.local(:[0-9]+)?/api/x$\""'
check "only /api and /legacy are routed (GET / -> 404)" 'req http://$IP:$NP/api/ | grep -q "portal-api v1" && [ "$(req -o /dev/null -w "%{http_code}" http://$IP:$NP/)" = 404 ]'
