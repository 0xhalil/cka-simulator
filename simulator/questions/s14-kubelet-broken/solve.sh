on cka-w2 '
  rm -f /etc/systemd/system/kubelet.service.d/20-tuning.conf
  sed -i "s#:6553#:6443#" /etc/kubernetes/kubelet.conf
  systemctl daemon-reload; systemctl enable kubelet; systemctl restart kubelet
'
kubectl wait --for=condition=Ready node/cka-w2 --timeout=120s
