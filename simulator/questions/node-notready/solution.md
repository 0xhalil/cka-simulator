```bash
ssh cka-cp2
k get nodes; k describe node cka-w2 | grep -A8 Conditions     # Kubelet stopped posting node status
ssh cka-w2
sudo -i
systemctl status kubelet                 # inactive (dead), disabled
systemctl start kubelet; journalctl -u kubelet -n 30 --no-pager
#  "unable to load client CA file /etc/kubernetes/pki/ca-bundle.crt: no such file"
vim /var/lib/kubelet/config.yaml          # clientCAFile: /etc/kubernetes/pki/ca.crt
systemctl enable --now kubelet && systemctl restart kubelet
exit; exit
k get nodes                               # cka-w2 Ready
```
Without `enable`, the node becomes NotReady again after a reboot.
