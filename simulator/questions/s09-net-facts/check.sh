F=/opt/course/s09-netfacts/facts.env
val() { grep -E "^$1=" $F 2>/dev/null | tail -1 | cut -d= -f2- | tr -d ' "\r'"'"; }
flag() { kubectl -n kube-system get pod -l component=$1 -o jsonpath='{.items[0].spec.containers[0].command}' | tr ',' '\n' | tr -d '"[]' | grep -- "^--$2=" | cut -d= -f2; }
nodeip() { jp node $1 '{.status.addresses[?(@.type=="InternalIP")].address}'; }
CNIF=$(on cka-w1 'ls /etc/cni/net.d/ | grep -E "\.(conflist|conf|json)$" | sort | head -1')
CNIPLUG=$(on cka-w1 "jq -r '.plugins[0].type // .type' /etc/cni/net.d/$CNIF")
check "POD_CIDR matches --cluster-cidr" '[ -n "$(val POD_CIDR)" ] && [ "$(val POD_CIDR)" = "$(flag kube-controller-manager cluster-cidr)" ]'
check "SERVICE_CIDR matches --service-cluster-ip-range" '[ -n "$(val SERVICE_CIDR)" ] && [ "$(val SERVICE_CIDR)" = "$(flag kube-apiserver service-cluster-ip-range)" ]'
check "DNS_SERVICE_IP is the kube-dns ClusterIP" '[ -n "$(val DNS_SERVICE_IP)" ] && [ "$(val DNS_SERVICE_IP)" = "$(jp -n kube-system svc kube-dns "{.spec.clusterIP}")" ]'
check "CNI_PLUGIN is the first plugin type of the CNI config" '[ -n "$(val CNI_PLUGIN)" ] && [ "$(val CNI_PLUGIN)" = "$CNIPLUG" ]'
check "CNI_CONFIG_FILE is the active CNI config path" '[ "$(val CNI_CONFIG_FILE)" = "/etc/cni/net.d/$CNIF" ]'
check "KUBE_PROXY_MODE is correct" 'm=$(kubectl -n kube-system get cm kube-proxy -o jsonpath="{.data.config\.conf}" | awk "/^mode:/{print \$2}" | tr -d "\""); [ -z "$m" ] && m=iptables; [ "$(val KUBE_PROXY_MODE)" = "$m" ]'
check "CP_INTERNAL_IP is the InternalIP of cka-cp1" '[ -n "$(val CP_INTERNAL_IP)" ] && [ "$(val CP_INTERNAL_IP)" = "$(nodeip cka-cp1)" ]'
check "WORKER_INTERNAL_IP is the InternalIP of cka-w1" '[ -n "$(val WORKER_INTERNAL_IP)" ] && [ "$(val WORKER_INTERNAL_IP)" = "$(nodeip cka-w1)" ]'
check "WORKER_IFACE holds the InternalIP on cka-w1" 'i=$(val WORKER_IFACE); [ -n "$i" ] && on cka-w1 "ip -o -4 addr show dev $i" | grep -qw "$(nodeip cka-w1)/[0-9]*"'
