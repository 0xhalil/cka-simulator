G="gateway.gateway.networking.k8s.io web-gateway -n web-app"
R="httproute.gateway.networking.k8s.io web-route -n web-app"
check "Gateway web-gateway uses GatewayClass nginx" "[ \"\$(jp $G '{.spec.gatewayClassName}')\" = nginx ]"
check "HTTPS listener on port 443 for gateway.web.k8s.local" "jp $G '{range .spec.listeners[*]}{.protocol}:{.port}:{.hostname}{\"\\n\"}{end}' | grep -qx 'HTTPS:443:gateway.web.k8s.local'"
check "listener terminates TLS with secret web-tls" "jp $G '{.spec.listeners[?(@.protocol==\"HTTPS\")].tls.certificateRefs[*].name}' | grep -qw web-tls"
check "Gateway is Programmed" "[ \"\$(jp $G '{.status.conditions[?(@.type==\"Programmed\")].status}')\" = True ]"
check "HTTPRoute web-route attached to web-gateway with hostname gateway.web.k8s.local" "jp $R '{.spec.parentRefs[*].name}' | grep -qw web-gateway && jp $R '{.spec.hostnames[*]}' | grep -qw gateway.web.k8s.local"
check "HTTPRoute sends / to web-svc:80" "[ \"\$(jp $R '{.spec.rules[*].backendRefs[*].name}:{.spec.rules[*].backendRefs[*].port}')\" = web-svc:80 ]"
check "HTTPRoute Accepted and ResolvedRefs" "[ \"\$(jp $R '{.status.parents[0].conditions[?(@.type==\"Accepted\")].status}{.status.parents[0].conditions[?(@.type==\"ResolvedRefs\")].status}')\" = TrueTrue ]"
check "HTTPS request through the Gateway returns the app" '
  NP=$(kubectl -n web-app get svc -l gateway.networking.k8s.io/gateway-name=web-gateway -o jsonpath="{.items[0].spec.ports[?(@.port==443)].nodePort}")
  for try in 1 2 3 4 5 6; do for ip in $(kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type==\"InternalIP\")].address}"); do
    curl -sk --max-time 5 --resolve gateway.web.k8s.local:$NP:$ip https://gateway.web.k8s.local:$NP/ | grep -q "served through the gateway" && exit 0
  done; sleep 5; done; exit 1'
check "Ingress web deleted" "! kubectl -n web-app get ingress web"
