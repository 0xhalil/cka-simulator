```bash
ssh cka-cp1
k get crd | grep cert-manager                              # to keep the header:
k get crd | grep -E '^NAME|cert-manager' > /opt/course/crd/resources.yaml
k explain certificate.spec.subject > /opt/course/crd/subject.yaml
```
Using `-o yaml` / `-o name` violates the "default output format" requirement.
