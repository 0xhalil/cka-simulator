```bash
ssh cka-cp2
k get nodes                                   # cp2 v1.37.x, w2 v1.36.x
k drain cka-w2 --ignore-daemonsets
ssh cka-w2
sudo -i
sed -i 's#/v1.36/#/v1.37/#' /etc/apt/sources.list.d/kubernetes.list
apt-get update && apt-cache madison kubeadm | head -3
apt-mark unhold kubeadm && apt-get install -y kubeadm='1.37.1-1.1' && apt-mark hold kubeadm
kubeadm upgrade node
apt-mark unhold kubelet kubectl && apt-get install -y kubelet='1.37.1-1.1' kubectl='1.37.1-1.1' && apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
exit; exit
k uncordon cka-w2
k get nodes
```
Match the package version **exactly** to the patch version in the `k get node cka-cp2` output (not the newest one).
