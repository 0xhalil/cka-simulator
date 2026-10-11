sed -i 's#path: /etc/kubernetes/certs$#path: /etc/kubernetes/pki#' /etc/kubernetes/manifests/kube-controller-manager.yaml
for i in $(seq 1 60); do curl -skf https://127.0.0.1:10257/healthz >/dev/null && break; sleep 3; done
kubectl -n kcm-lab rollout status deploy pulse --timeout=120s
kubectl -n kcm-lab rollout status deploy beacon --timeout=120s
