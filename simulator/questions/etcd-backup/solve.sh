ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/course/etcd/etcd-snapshot.db
etcdutl snapshot status /opt/course/etcd/etcd-snapshot.db -w table > /opt/course/etcd/snapshot-status.txt
