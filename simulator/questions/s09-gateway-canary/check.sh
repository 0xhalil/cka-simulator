NS=s09-canary; G="-n $NS gateway.gateway.networking.k8s.io canary-gw"; R="-n $NS httproute.gateway.networking.k8s.io canary-route"
NP=$(kubectl -n $NS get svc -l gateway.networking.k8s.io/gateway-name=canary-gw -o jsonpath='{.items[0].spec.ports[?(@.port==80)].nodePort}' 2>/dev/null)
IP=$(jp node cka-w1 '{.status.addresses[?(@.type=="InternalIP")].address}')
req() { curl -s --max-time 4 -H "Host: canary.s09.local" "$@" http://$IP:$NP/; }
check "Gateway canary-gw: class nginx, HTTP listener http:80 for canary.s09.local" '[ "$(jp $G "{.spec.gatewayClassName}|{range .spec.listeners[*]}{.name}:{.protocol}:{.port}:{.hostname};{end}")" = "nginx|http:HTTP:80:canary.s09.local;" ]'
check "Gateway canary-gw is Programmed" 'kubectl wait $G --for=condition=Programmed --timeout=60s'
check "HTTPRoute canary-route attached (Accepted, ResolvedRefs)" '[ "$(jp $R "{.spec.parentRefs[0].name}|{.spec.hostnames[*]}|{.status.parents[0].conditions[?(@.type==\"Accepted\")].status}{.status.parents[0].conditions[?(@.type==\"ResolvedRefs\")].status}")" = "canary-gw|canary.s09.local|TrueTrue" ]'
check "default rule weights app-v1=80 / app-v2=20 (or equivalent 4:1 ratio)" 'kubectl get $R -o json | jq -e "[.spec.rules[] | select(((.matches // []) | map(.headers // []) | flatten | length) == 0) | .backendRefs | map({(.name): (.weight // 1)}) | add] | .[0] as \$w | (\$w[\"app-v1\"] == 4 * \$w[\"app-v2\"]) and (\$w | length == 2)"'
check "header X-Canary: always -> only app-v2 (20 requests)" 'for t in 1 2 3; do o=$(for i in $(seq 20); do req -H "X-Canary: always"; echo; done); b=$(grep -cx app-v2 <<<"$o"); a=$(grep -cx app-v1 <<<"$o"); [ $a = 0 ] && [ $b -ge 15 ] && exit 0; sleep 5; done; exit 1'
check "canary responses carry X-Canary-Served: true" 'for t in 1 2 3; do req -i -H "X-Canary: always" | grep -iq "^X-Canary-Served: *true" && exit 0; sleep 5; done; exit 1'
check "requests without the header are split (mostly app-v1, some app-v2)" 'for t in 1 2 3; do o=$(for i in $(seq 40); do req; done); a=$(grep -cx app-v1 <<<"$o"); b=$(grep -cx app-v2 <<<"$o"); [ $a -ge 22 ] && [ $b -ge 1 ] && [ $((a+b)) = 40 ] && exit 0; sleep 5; done; exit 1'
check "normal responses do not carry X-Canary-Served" '! req -i | grep -iq "^X-Canary-Served" && req | grep -q "^app-v"'
