sed -i 's#--kubeconfig=/etc/kubernetes/scheduler.config#--kubeconfig=/etc/kubernetes/scheduler.conf#' /etc/kubernetes/manifests/kube-scheduler.yaml
sleep 30
kubectl -n ops rollout status deploy orbit --timeout=120s
