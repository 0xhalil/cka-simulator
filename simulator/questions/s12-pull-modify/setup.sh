course_dir s12-pull
for u in root candidate; do sudo -u $u -H helm repo remove s12-pi >/dev/null 2>&1 || true; done
helm -n s12-docs uninstall docs >/dev/null 2>&1 || true
kubectl delete ns s12-docs --ignore-not-found --wait=true --timeout=120s >/dev/null 2>&1
