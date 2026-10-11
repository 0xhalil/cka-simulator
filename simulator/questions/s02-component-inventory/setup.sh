course_dir s02-inventory
cat > /opt/course/s02-inventory/components.txt <<'TXT'
kube-apiserver:
kube-scheduler:
kube-controller-manager:
etcd:
kubelet:
kube-proxy:
coredns:
TXT
chown -R candidate: /opt/course/s02-inventory
