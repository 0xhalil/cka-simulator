check "node cka-w2 is Ready" "kubectl wait --for=condition=Ready node/cka-w2 --timeout=60s"
check "kubelet service is active and enabled on cka-w2" "on cka-w2 'systemctl is-active kubelet && systemctl is-enabled kubelet'"
check "running kubelet process is /usr/bin/kubelet" "[ \"\$(on cka-w2 'readlink /proc/\$(pgrep -xo kubelet)/exe')\" = /usr/bin/kubelet ]"
check "kubelet kubeconfig points to https://192.168.104.1:6443" "on cka-w2 'grep -Eq \"server: https://192.168.104.1:6443\$\" /etc/kubernetes/kubelet.conf'"
