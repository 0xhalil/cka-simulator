# break the kubelet on cka-w2: wrong client CA path + service stopped and disabled
on cka-w2 '
  set -e
  CFG=/var/lib/kubelet/config.yaml
  sed -i "s#clientCAFile: .*#clientCAFile: /etc/kubernetes/pki/ca-bundle.crt#" $CFG
  systemctl disable --now kubelet >/dev/null 2>&1
'
for i in $(seq 1 30); do
  [ "$(kubectl get node cka-w2 -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" != True ] && break
  sleep 5
done
