api() { for i in $(seq 1 30); do kubectl get --raw=/readyz >/dev/null 2>&1 && return 0; sleep 3; done; return 1; }
API=0; api && API=1
M=/etc/kubernetes/manifests/kube-apiserver.yaml
check "kube-apiserver manifest is valid YAML" "python3 -c 'import yaml,sys; yaml.safe_load(open(\"$M\"))'"
check "kube-apiserver uses the etcd client port 2379" "grep -Eq -- '--etcd-servers=https://(127\.0\.0\.1|192\.168\.104\.1):2379\$' $M"
check "kube-apiserver is running and ready (/readyz)" "[ $API = 1 ]"
check "kubectl works (list nodes)" "kubectl get nodes"
check "/opt/course/apiserver/flag.txt names the flag --etcd-servers" "grep -Eqx -- '(--)?etcd-servers' /opt/course/apiserver/flag.txt"
guard "no extra files in /etc/kubernetes/manifests" "[ \$(ls /etc/kubernetes/manifests | wc -l) -eq 4 ]"
