D=/opt/course/s02-inventory; M=/etc/kubernetes/manifests
cat > $D/components.txt <<'TXT'
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
kubelet: process
kube-proxy: daemonset
coredns: deployment
TXT
f() { grep -oE -- "--$1=[^ ]+" $2 | cut -d= -f2-; }
cat > $D/facts.txt <<TXT
STATIC_POD_PATH=$(awk '/^staticPodPath:/{print $2}' /var/lib/kubelet/config.yaml)
ETCD_DATA_DIR=$(f data-dir $M/etcd.yaml)
ETCD_SERVERS=$(f etcd-servers $M/kube-apiserver.yaml)
ETCD_IMAGE_TAG=$(grep image: $M/etcd.yaml | head -1 | awk -F: '{print $NF}')
SERVICE_CIDR=$(f service-cluster-ip-range $M/kube-apiserver.yaml)
POD_CIDR=$(f cluster-cidr $M/kube-controller-manager.yaml)
CLUSTER_DNS_IP=$(kubectl -n kube-system get svc kube-dns -o jsonpath='{.spec.clusterIP}')
TXT
cat $D/facts.txt
