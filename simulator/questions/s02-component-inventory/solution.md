In a kubeadm cluster, the control plane components run as **static pods**: their manifests live in the kubelet's `staticPodPath` directory (`/etc/kubernetes/manifests`). The node name suffix on the pod name (`-cka-cp1`) and `ownerReferences.kind: Node` give this away. `kubelet`, on the other hand, is not a Pod but a **process** run by systemd (`systemctl status kubelet`). `kube-proxy` runs on every node, so it is a **DaemonSet**; CoreDNS is a **Deployment**.

Trap: `kubectl get pods -n kube-system` never shows the kubelet; also, ETCD_SERVERS must be read from the apiserver's `--etcd-servers` flag, not from the etcd manifest. POD_CIDR is the controller-manager's `--cluster-cidr` flag (don't confuse it with SERVICE_CIDR).

```bash
ssh cka-cp1
sudo -i
k -n kube-system get pods -o wide; k -n kube-system get ds,deploy
k -n kube-system get pod kube-apiserver-cka-cp1 -o jsonpath='{.metadata.ownerReferences[0].kind}'   # Node
systemctl status kubelet
grep staticPodPath /var/lib/kubelet/config.yaml
grep -- --data-dir /etc/kubernetes/manifests/etcd.yaml
grep image: /etc/kubernetes/manifests/etcd.yaml
grep -E -- '--etcd-servers|--service-cluster-ip-range' /etc/kubernetes/manifests/kube-apiserver.yaml
grep -- --cluster-cidr /etc/kubernetes/manifests/kube-controller-manager.yaml
k -n kube-system get svc kube-dns
```

```
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
kubelet: process
kube-proxy: daemonset
coredns: deployment
```
```
STATIC_POD_PATH=/etc/kubernetes/manifests
ETCD_DATA_DIR=/var/lib/etcd
ETCD_SERVERS=https://127.0.0.1:2379
ETCD_IMAGE_TAG=3.7.0-0
SERVICE_CIDR=10.96.0.0/12
POD_CIDR=10.244.0.0/16
CLUSTER_DNS_IP=10.96.0.10
```
