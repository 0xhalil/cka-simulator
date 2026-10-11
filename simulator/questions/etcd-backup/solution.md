```bash
ssh cka-cp2
sudo -i
grep -E 'listen-client-urls|cert-file|key-file|trusted-ca-file' /etc/kubernetes/manifests/etcd.yaml
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/course/etcd/etcd-snapshot.db
etcdutl snapshot status /opt/course/etcd/etcd-snapshot.db -w table > /opt/course/etcd/snapshot-status.txt
```
`etcdctl snapshot status` was removed in etcd v3.6 → use `etcdutl`.
