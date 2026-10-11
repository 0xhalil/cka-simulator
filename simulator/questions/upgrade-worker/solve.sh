CPV=$(kubectl get node cka-cp2 -o jsonpath='{.status.nodeInfo.kubeletVersion}'); M=$(echo $CPV | sed 's/^v//' | cut -d. -f1-2)
kubectl drain cka-w2 --ignore-daemonsets --delete-emptydir-data --force
on cka-w2 "
  set -e
  sed -i -E 's#/v[0-9]+\.[0-9]+/deb/#/v$M/deb/#' /etc/apt/sources.list.d/kubernetes.list
  apt-get update -qq
  P=\$(apt-cache madison kubeadm | awk '{print \$3}' | grep '^${CPV#v}-' | head -1)
  apt-mark unhold kubeadm >/dev/null; apt-get install -y -qq kubeadm=\$P >/dev/null; apt-mark hold kubeadm >/dev/null
  kubeadm upgrade node
  apt-mark unhold kubelet kubectl >/dev/null; apt-get install -y -qq kubelet=\$P kubectl=\$P >/dev/null; apt-mark hold kubelet kubectl >/dev/null
  systemctl daemon-reload; systemctl restart kubelet
"
kubectl uncordon cka-w2
