F=/opt/course/s09-netfacts/facts.env
PCIDR=$(kubectl -n kube-system get pod -l component=kube-controller-manager -o yaml | grep -- --cluster-cidr= | cut -d= -f2)
SCIDR=$(kubectl -n kube-system get pod -l component=kube-apiserver -o yaml | grep -- --service-cluster-ip-range= | cut -d= -f2)
DNS=$(kubectl -n kube-system get svc kube-dns -o jsonpath='{.spec.clusterIP}')
CONF=$(ssh -o BatchMode=yes cka-w1 'ls /etc/cni/net.d/*.conflist | sort | head -1' </dev/null)
PLUG=$(ssh -o BatchMode=yes cka-w1 "jq -r '.plugins[0].type' $CONF" </dev/null)
MODE=$(kubectl -n kube-system get cm kube-proxy -o jsonpath='{.data.config\.conf}' | awk '/^mode:/{print $2}' | tr -d '"')
CPIP=$(kubectl get node cka-cp1 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
WIP=$(kubectl get node cka-w1 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
IF=$(ssh -o BatchMode=yes cka-w1 "ip -o -4 addr | grep -w $WIP | awk '{print \$2}'" </dev/null)
cat > $F <<E
POD_CIDR=$PCIDR
SERVICE_CIDR=$SCIDR
DNS_SERVICE_IP=$DNS
CNI_PLUGIN=$PLUG
CNI_CONFIG_FILE=$CONF
KUBE_PROXY_MODE=${MODE:-iptables}
CP_INTERNAL_IP=$CPIP
WORKER_INTERNAL_IP=$WIP
WORKER_IFACE=$IF
E
cat $F
