CPV=$(kubectl get node cka-cp2 -o jsonpath='{.status.nodeInfo.kubeletVersion}')     # e.g. v1.37.1
CPMINOR=$(echo $CPV | sed 's/^v//' | cut -d. -f1-2)
PREV=$(echo $CPMINOR | awk -F. '{print $1"."$2-1}')
WV=$(on cka-w2 'kubelet --version' | awk '{print $2}')
on cka-w2 "sed -i -E 's#/v[0-9]+\.[0-9]+/deb/#/v$PREV/deb/#g' /etc/apt/sources.list.d/kubernetes.list"
case $WV in
  v$PREV.*) echo "cka-w2 already on $WV" ;;
  *)
    echo "resetting cka-w2 from $WV to $PREV"
    kubectl drain cka-w2 --ignore-daemonsets --delete-emptydir-data --force --timeout=120s >/dev/null 2>&1 || true
    kubectl delete node cka-w2 --wait=true >/dev/null 2>&1 || true
    JOIN=$(kubeadm token create --print-join-command)
    on cka-w2 "
      set -e
      export DEBIAN_FRONTEND=noninteractive
      kubeadm reset -f >/dev/null 2>&1
      rm -rf /etc/cni/net.d/* /var/lib/kubelet/config.yaml
      apt-get update -qq
      V=\$(apt-cache madison kubeadm | awk '{print \$3}' | sort -V | tail -1)
      apt-get install -y -qq --allow-downgrades --allow-change-held-packages kubeadm=\$V kubelet=\$V kubectl=\$V >/dev/null
      apt-mark hold kubeadm kubelet kubectl >/dev/null
      systemctl enable kubelet >/dev/null
      $JOIN
    "
    for i in $(seq 1 60); do kubectl get node cka-w2 >/dev/null 2>&1 && break; sleep 3; done
    kubectl wait --for=condition=Ready node/cka-w2 --timeout=300s
    ;;
esac
kubectl uncordon cka-w2 >/dev/null 2>&1 || true
