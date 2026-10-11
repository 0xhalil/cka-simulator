N="-n s02-svc"
eps() { kubectl $N get endpointslice -l kubernetes.io/service-name=orders-svc -o jsonpath='{range .items[*].endpoints[?(@.conditions.ready==true)]}{.targetRef.name}{"\n"}{end}' | sort; }
stable() { kubectl $N get pod -l app=orders,track=stable --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | sort; }
guard "orders-svc keeps type ClusterIP and port 8080" '[ "$(jp $N svc orders-svc "{.spec.type}|{.spec.ports[*].port}")" = "ClusterIP|8080" ]'
check "orders-svc endpoints are exactly the 2 stable orders Pods" 'for i in $(seq 10); do [ -n "$(stable)" ] && [ "$(eps)" = "$(stable)" ] && [ "$(eps | wc -l)" = 2 ] && exit 0; sleep 3; done; exit 1'
check "requests to orders-svc:8080 are answered by nginx (stable) only" '
  ip=$(jp $N svc orders-svc "{.spec.clusterIP}"); [ -n "$ip" ] || exit 1; ok=0
  for i in $(seq 12); do r=$(curl -s --max-time 3 http://$ip:8080/); echo "$r" | grep -q canary-build && exit 1; echo "$r" | grep -q "Welcome to nginx" && ok=$((ok+1)); done; [ $ok -ge 10 ]'
check "/opt/course/s02-svc/endpoints.txt lists the endpoint Pods" '[ -n "$(eps)" ] && [ "$(grep -v "^[[:space:]]*$" /opt/course/s02-svc/endpoints.txt | sed "s/[[:space:]]//g; s#^pod/##" | sort)" = "$(eps)" ]'
guard "Deployments orders and orders-canary unchanged" '[ "$(jp $N deploy orders "{.spec.template.metadata.labels.track}{.spec.replicas}")" = stable2 ] && [ "$(jp $N deploy orders-canary "{.spec.template.metadata.labels.track}{.spec.replicas}")" = canary1 ]'
