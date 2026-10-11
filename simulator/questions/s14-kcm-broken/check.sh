for i in $(seq 1 30); do kubectl get --raw=/readyz >/dev/null 2>&1 && break; sleep 3; done
M=/etc/kubernetes/manifests/kube-controller-manager.yaml
check "controller-manager mounts the host directory /etc/kubernetes/pki" "python3 -c '
import yaml; p=yaml.safe_load(open(\"$M\")); s=p[\"spec\"]
v={x[\"name\"]:x.get(\"hostPath\",{}).get(\"path\") for x in s[\"volumes\"]}
assert any(m[\"mountPath\"]==\"/etc/kubernetes/pki\" and v.get(m[\"name\"])==\"/etc/kubernetes/pki\" for m in s[\"containers\"][0][\"volumeMounts\"])'"
check "kube-controller-manager is running and healthy" "curl -skf https://127.0.0.1:10257/healthz"
check "Deployment pulse has 2/2 available replicas" "kubectl -n kcm-lab wait --for=jsonpath='{.status.availableReplicas}'=2 deploy/pulse --timeout=90s"
check "Deployment beacon has 3/3 available replicas" "kubectl -n kcm-lab wait --for=jsonpath='{.status.availableReplicas}'=3 deploy/beacon --timeout=60s"
guard "Deployment pulse not modified" "[ \"\$(jp deploy pulse -n kcm-lab '{.metadata.generation}')\" = 1 ]"
guard "no extra files in /etc/kubernetes/manifests" "[ \$(ls /etc/kubernetes/manifests | wc -l) -eq 4 ]"
