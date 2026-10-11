kubectl get crd | grep -E '^NAME|cert-manager' > /opt/course/crd/resources.yaml
kubectl explain certificate.spec.subject > /opt/course/crd/subject.yaml
