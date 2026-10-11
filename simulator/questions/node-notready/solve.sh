on cka-w2 'sed -i "s#clientCAFile: .*#clientCAFile: /etc/kubernetes/pki/ca.crt#" /var/lib/kubelet/config.yaml; systemctl enable --now kubelet; systemctl restart kubelet'
kubectl wait --for=condition=Ready node/cka-w2 --timeout=120s
