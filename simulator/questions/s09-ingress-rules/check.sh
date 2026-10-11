NS=s09-shop; I="-n $NS ingress shop"
paths() { kubectl get $I -o jsonpath='{range .spec.rules[?(@.host=="shop.s09.local")].http.paths[*]}{.path}|{.pathType}|{.backend.service.name}|{.backend.service.port.number}{.backend.service.port.name}{"\n"}{end}' 2>/dev/null; }
check "Secret shop-tls is type kubernetes.io/tls with the given cert" '[ "$(jp -n $NS secret shop-tls "{.type}")" = kubernetes.io/tls ] && [ "$(jp -n $NS secret shop-tls "{.data.tls\.crt}" | base64 -d | openssl x509 -noout -fingerprint -sha256)" = "$(openssl x509 -in /opt/course/s09-ingress/shop.crt -noout -fingerprint -sha256)" ]'
check "Ingress shop uses IngressClass nginx" '[ "$(jp $I "{.spec.ingressClassName}")" = nginx ]'
check "TLS for shop.s09.local with secret shop-tls" '[ "$(jp $I "{.spec.tls[?(@.secretName==\"shop-tls\")].hosts[*]}")" = shop.s09.local ]'
check "/pay (Prefix) -> shop-pay:8282" 'paths | grep -Eqx "/pay[|]Prefix[|]shop-pay[|](8282|http)"'
check "rewrite-target annotation rewrites to /" '[ "$(jp $I "{.metadata.annotations.nginx\.ingress\.kubernetes\.io/rewrite-target}")" = / ]'
check "/status (Exact) -> shop-ui:80" 'paths | grep -Eqx "/status[|]Exact[|]shop-ui[|](80|http)"'
check "/ (Prefix) -> shop-ui:80" 'paths | grep -Eqx "/[|]Prefix[|]shop-ui[|](80|http)"'
check "defaultBackend is shop-default:80" '[ "$(jp $I "{.spec.defaultBackend.service.name}:{.spec.defaultBackend.service.port.number}{.spec.defaultBackend.service.port.name}")" = shop-default:80 ] || [ "$(jp $I "{.spec.defaultBackend.service.name}:{.spec.defaultBackend.service.port.name}")" = shop-default:http ]'
check "no other paths for shop.s09.local and only one rule" '[ "$(paths | wc -l)" = 3 ] && [ "$(jp $I "{.spec.rules[*].host}")" = shop.s09.local ]'
