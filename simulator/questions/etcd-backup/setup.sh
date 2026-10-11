course_dir etcd
kubectl delete ns etcd-marker --ignore-not-found --wait=true >/dev/null 2>&1
kubectl create ns etcd-marker >/dev/null
date +%s > /root/.etcd-backup-setup-time
chown -R candidate: /opt/course
