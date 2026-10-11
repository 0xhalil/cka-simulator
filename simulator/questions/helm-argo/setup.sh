course_dir helm
helm -n helm-apps uninstall demo >/dev/null 2>&1 || true
kubectl delete ns helm-apps argocd --ignore-not-found --wait=true >/dev/null 2>&1
for u in root candidate; do
  sudo -u $u -H helm repo remove argo podinfo >/dev/null 2>&1 || true
done
