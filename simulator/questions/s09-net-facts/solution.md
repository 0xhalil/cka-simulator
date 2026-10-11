Every value is read from the live source — don't write defaults from memory (e.g. the pod CIDR is given with `--pod-network-cidr` in kubeadm and shows up as `--cluster-cidr` on the controller-manager).

```bash
ssh cka-cp1
k -n kube-system get pod -l component=kube-controller-manager -o yaml | grep cluster-cidr     # POD_CIDR
k -n kube-system get pod -l component=kube-apiserver -o yaml | grep service-cluster-ip-range  # SERVICE_CIDR
#   (alternative: cat /etc/kubernetes/manifests/kube-apiserver.yaml)
k -n kube-system get svc kube-dns                       # DNS_SERVICE_IP (Service name kube-dns, pods are CoreDNS)
k -n kube-system get cm kube-proxy -o yaml | grep mode  # if empty ("") the default = iptables
#   (alternative: k -n kube-system logs <kube-proxy-pod> | grep -i proxier)
k get nodes -o wide                                     # INTERNAL-IP

ssh cka-w1
ls /etc/cni/net.d/                 # kubelet uses the alphabetically FIRST file -> 10-calico.conflist
jq '.plugins[].type' /etc/cni/net.d/10-calico.conflist   # "calico", "portmap" -> first: calico
ip -o -4 addr | grep 192.168.104.3                        # WORKER_IFACE (eth0)
ls /opt/cni/bin                                           # plugin binaries
```

`/opt/course/s09-netfacts/facts.env`:
```
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/12
DNS_SERVICE_IP=10.96.0.10
CNI_PLUGIN=calico
CNI_CONFIG_FILE=/etc/cni/net.d/10-calico.conflist
KUBE_PROXY_MODE=iptables
CP_INTERNAL_IP=<cka-cp1 InternalIP>
WORKER_INTERNAL_IP=<cka-w1 InternalIP>
WORKER_IFACE=eth0
```
Trap: `calico-kubeconfig` is not a CNI config file; a flannel binary under `/opt/cni/bin` doesn't mean the CNI in use is flannel.
