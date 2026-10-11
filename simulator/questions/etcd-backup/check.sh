F=/opt/course/etcd/etcd-snapshot.db
check "snapshot file exists and was taken after the exam started" "[ -s $F ] && [ \$(stat -c %Y $F) -ge \$(cat /root/.etcd-backup-setup-time) ]"
check "snapshot is a valid etcd snapshot" "etcdutl snapshot status $F"
check "snapshot contains the current cluster data (namespace etcd-marker)" "grep -aq /registry/namespaces/etcd-marker $F"
guard "etcd is still healthy" "kubectl -n kube-system wait --for=condition=Ready pod/etcd-cka-cp2 --timeout=30s"
check "snapshot-status.txt contains table output (HASH, REVISION, TOTAL KEYS, TOTAL SIZE)" "grep -q HASH /opt/course/etcd/snapshot-status.txt && grep -q REVISION /opt/course/etcd/snapshot-status.txt && grep -q 'TOTAL KEYS' /opt/course/etcd/snapshot-status.txt"
