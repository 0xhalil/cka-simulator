```bash
ssh cka-cp1
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm show values argo/argo-cd --version 10.9.5 | grep -A3 '^crds:'      # crds.install
helm template argocd argo/argo-cd --version 10.9.5 -n argocd --set crds.install=false > /opt/course/helm/argo-helm.yaml

helm repo add podinfo https://stefanprodan.github.io/podinfo
helm show values podinfo/podinfo --version 6.14.1 | grep -A8 '^service:'
helm install demo podinfo/podinfo --version 6.14.1 -n helm-apps --create-namespace \
  --set replicaCount=2 --set service.type=NodePort --set service.nodePort=30880
helm -n helm-apps list
```
`--skip-crds` only skips CRDs in the chart's `crds/` directory; the argo-cd chart renders its CRDs as templates, so `crds.install=false` is required.
