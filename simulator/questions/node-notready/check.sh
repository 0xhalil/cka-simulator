check "node cka-w2 is Ready" "kubectl wait --for=condition=Ready node/cka-w2 --timeout=60s"
check "kubelet service is active on cka-w2" "on cka-w2 'systemctl is-active kubelet'"
check "kubelet service is enabled (survives reboot)" "on cka-w2 'systemctl is-enabled kubelet'"
check "kubelet clientCAFile points to the cluster CA" "on cka-w2 'grep -q \"clientCAFile: /etc/kubernetes/pki/ca.crt\" /var/lib/kubelet/config.yaml'"
