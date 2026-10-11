There are two errors: the manifest **can't be parsed as YAML** (kubelet never creates the pod), and once fixed the apiserver tries to connect to the **wrong etcd port** (2380 = peer port) and crashes.

```bash
ssh cka-cp2
sudo -i
crictl ps -a | grep kube-apiserver          # no container at all -> kubelet can't read the manifest
journalctl -u kubelet --no-pager | grep -i 'kube-apiserver' | tail
#   "Could not process manifest file" ... yaml: ... found unexpected end of stream
vim /etc/kubernetes/manifests/kube-apiserver.yaml
#   - "--advertise-address=192.168.104.1      -> remove the quote
watch crictl ps -a                          # kube-apiserver Exited / restarting
crictl logs $(crictl ps -a --name kube-apiserver -q | head -1) 2>&1 | tail
#   dial tcp 127.0.0.1:2380: connect: connection refused
grep -E 'listen-client-urls' /etc/kubernetes/manifests/etcd.yaml    # client port = 2379
vim /etc/kubernetes/manifests/kube-apiserver.yaml
#   - --etcd-servers=https://127.0.0.1:2379
echo '--etcd-servers' > /opt/course/apiserver/flag.txt
kubectl get nodes
```

Tip: if kubectl doesn't work, use `crictl ps -a`, `crictl logs <id>`, `/var/log/pods/kube-system_kube-apiserver-*/` and `journalctl -u kubelet`. 2379 = etcd client, 2380 = etcd peer. Don't leave a backup inside `/etc/kubernetes/manifests/` (kubelet will try to run it too).
