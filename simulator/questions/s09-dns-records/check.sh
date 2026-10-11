NS=s09-dns; D=/opt/course/s09-dns; Z=cluster.local
SVC=$(jp -n $NS sts ledger '{.spec.serviceName}')
CIP=$(jp -n $NS svc catalog '{.spec.clusterIP}')
L0=$(jp -n $NS pod ledger-0 '{.status.podIP}'); L1=$(jp -n $NS pod ledger-1 '{.status.podIP}')
CP=$(kubectl -n $NS get pod -l app=catalog -o jsonpath='{.items[0].status.podIP}')
ns_has() { grep -Eq "^Name:[[:space:]]+$2\.?$" $D/$1 && grep -Eq "^Address:[[:space:]]+$3$" $D/$1 && grep -q "^Server:" $D/$1; }
guard "StatefulSet ledger unchanged" '[ "$SVC" = ledger-hl ] && [ "$(jp -n $NS sts ledger "{.metadata.generation}")" = 1 ]'
check "Service ledger-hl is headless and selects the ledger Pods" '[ "$(jp -n $NS svc ledger-hl "{.spec.clusterIP}")" = None ] && [ "$(kubectl -n $NS get endpointslice -l kubernetes.io/service-name=ledger-hl -o jsonpath="{range .items[*].endpoints[*]}{.targetRef.name}{\"\n\"}{end}" | sort | tr "\n" " ")" = "ledger-0 ledger-1 " ]'
check "ledger-1.ledger-hl resolves inside the cluster" 'kubectl -n s09-dns-client exec client -- nslookup ledger-1.ledger-hl.$NS.svc.$Z | grep -q "Address: *$L1"'
check "catalog-svc.txt: FQDN of Service catalog -> ClusterIP" 'ns_has catalog-svc.txt "catalog\.$NS\.svc\.$Z" "$CIP"'
check "ledger-1.txt: ledger-1.ledger-hl.s09-dns.svc.cluster.local -> Pod IP" '[ -n "$L1" ] && ns_has ledger-1.txt "ledger-1\.ledger-hl\.$NS\.svc\.$Z" "$L1"'
check "ledger-all.txt: headless Service returns both ledger Pod IPs" '[ -n "$L0" ] && ns_has ledger-all.txt "ledger-hl\.$NS\.svc\.$Z" "$L0" && ns_has ledger-all.txt "ledger-hl\.$NS\.svc\.$Z" "$L1"'
check "catalog-pod.txt: Pod A record <ip-with-dashes>.s09-dns.pod.cluster.local" '[ -n "$CP" ] && ns_has catalog-pod.txt "${CP//./-}\.$NS\.pod\.$Z" "$CP"'
