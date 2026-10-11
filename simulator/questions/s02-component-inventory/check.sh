F=/opt/course/s02-inventory/components.txt; G=/opt/course/s02-inventory/facts.txt
M=/etc/kubernetes/manifests
val() { grep -E "^[[:space:]]*$1[[:space:]]*[:=]" "$2" 2>/dev/null | head -1 | sed -E 's/^[^:=]*[:=][[:space:]]*//; s/[[:space:]"]+$//; s/^"//'; }
flag() { grep -oE -- "--$1=[^[:space:]\"]+" "$2" | head -1 | cut -d= -f2-; }
check "kube-apiserver, kube-scheduler, kube-controller-manager and etcd: static-pod" '
  for c in kube-apiserver kube-scheduler kube-controller-manager etcd; do [ "$(val $c $F)" = static-pod ] || exit 1; done'
check "kubelet: process" '[ "$(val kubelet $F)" = process ]'
check "kube-proxy: daemonset" '[ "$(val kube-proxy $F)" = daemonset ]'
check "coredns: deployment" '[ "$(val coredns $F)" = deployment ]'
check "STATIC_POD_PATH is correct" '[ -n "$(val STATIC_POD_PATH $G)" ] && [ "$(val STATIC_POD_PATH $G | sed "s:/*$::")" = "$(grep -E "^staticPodPath:" /var/lib/kubelet/config.yaml | awk "{print \$2}" | sed "s:/*$::")" ]'
check "ETCD_DATA_DIR is correct" '[ -n "$(val ETCD_DATA_DIR $G)" ] && [ "$(val ETCD_DATA_DIR $G | sed "s:/*$::")" = "$(flag data-dir $M/etcd.yaml)" ]'
check "ETCD_SERVERS is correct" '[ -n "$(val ETCD_SERVERS $G)" ] && [ "$(val ETCD_SERVERS $G)" = "$(flag etcd-servers $M/kube-apiserver.yaml)" ]'
check "ETCD_IMAGE_TAG is correct" '[ -n "$(val ETCD_IMAGE_TAG $G)" ] && [ "$(val ETCD_IMAGE_TAG $G)" = "$(grep -E "image:" $M/etcd.yaml | head -1 | sed -E "s/.*://; s/[[:space:]]//g")" ]'
check "SERVICE_CIDR is correct" '[ -n "$(val SERVICE_CIDR $G)" ] && [ "$(val SERVICE_CIDR $G)" = "$(flag service-cluster-ip-range $M/kube-apiserver.yaml)" ]'
check "POD_CIDR is correct" '[ -n "$(val POD_CIDR $G)" ] && [ "$(val POD_CIDR $G)" = "$(flag cluster-cidr $M/kube-controller-manager.yaml)" ]'
check "CLUSTER_DNS_IP is correct" '[ -n "$(val CLUSTER_DNS_IP $G)" ] && [ "$(val CLUSTER_DNS_IP $G)" = "$(jp -n kube-system svc kube-dns "{.spec.clusterIP}")" ]'
guard "control plane manifests untouched (all 4 static pods Running)" '[ "$(kubectl -n kube-system get pod -l tier=control-plane --field-selector=status.phase=Running -o name | wc -l)" -ge 4 ]'
