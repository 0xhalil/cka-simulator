M=/etc/kubernetes/manifests/kube-apiserver.yaml
sed -i -e 's#^    - "--advertise-address=#    - --advertise-address=#' -e 's#--etcd-servers=https://127.0.0.1:2380#--etcd-servers=https://127.0.0.1:2379#' $M
echo '--etcd-servers' > /opt/course/apiserver/flag.txt
for i in $(seq 1 60); do kubectl get --raw=/readyz >/dev/null 2>&1 && break; sleep 3; done
