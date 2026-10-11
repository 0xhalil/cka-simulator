NS=s09-orbit; D=/opt/course/s09-orbit
CIP=$(jp -n $NS svc orbit-svc '{.spec.clusterIP}')
PODIPS=$(kubectl -n $NS get pod -l app=orbit-api -o jsonpath='{.items[*].status.podIP}')
CHAIN=$(on cka-w1 "iptables -t nat -S KUBE-SERVICES" | grep -- "-d $CIP/32" | grep -o 'KUBE-SVC-[A-Z0-9]*' | head -1)
guard "Deployment orbit-api unchanged" '[ "$(jp -n $NS deploy orbit-api "{.metadata.generation}")" = 1 ] && [ "$(jp -n $NS deploy orbit-api "{.status.readyReplicas}")" = 2 ]'
guard "Service keeps type ClusterIP and port 80" '[ "$(jp -n $NS svc orbit-svc "{.spec.type}:{.spec.ports[0].port}")" = ClusterIP:80 ]'
check "orbit-svc has 2 ready endpoints" '[ "$(kubectl -n $NS get endpointslice -l kubernetes.io/service-name=orbit-svc -o jsonpath="{range .items[*].endpoints[*]}{.conditions.ready}{\"\n\"}{end}" | grep -c true)" = 2 ]'
check "curl ClusterIP:80 returns the app" 'for t in 1 2 3 4 5; do curl -s --max-time 3 http://$CIP/ | grep -q "orbit-api:" && exit 0; sleep 2; done; exit 1'
check "iptables.txt contains the KUBE-SERVICES rule for the ClusterIP" 'grep -- "-A KUBE-SERVICES" $D/iptables.txt | grep -- "-d $CIP/32" | grep -q "s09-orbit/orbit-svc"'
check "iptables.txt contains a DNAT rule to every endpoint (podIP:8080)" '[ -n "$PODIPS" ] && for ip in $PODIPS; do grep -- "-j DNAT" $D/iptables.txt | grep -q -- "--to-destination $ip:8080" || exit 1; done'
check "iptables.txt contains the KUBE-SVC load-balancing rules" '[ -n "$CHAIN" ] && [ "$(grep -c -- "-A $CHAIN .*-j KUBE-SEP-" $D/iptables.txt)" -ge 2 ] && ! grep -v -q "s09-orbit/orbit-svc" $D/iptables.txt'
check "svc-chain.txt contains the KUBE-SVC chain of orbit-svc" '[ -n "$CHAIN" ] && [ "$(tr -d " \n\r" < $D/svc-chain.txt)" = "$CHAIN" ]'
