course_dir crd
kubectl get crd certificates.cert-manager.io >/dev/null 2>&1 || \
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.18.2/cert-manager.crds.yaml >/dev/null
kubectl wait --for=condition=Established crd/certificates.cert-manager.io --timeout=60s >/dev/null
chown -R candidate: /opt/course
