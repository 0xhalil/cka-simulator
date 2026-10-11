helm repo add argo https://argoproj.github.io/argo-helm
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
helm template argocd argo/argo-cd --version 10.9.5 -n argocd --set crds.install=false > /opt/course/helm/argo-helm.yaml
helm install demo podinfo/podinfo --version 6.14.1 -n helm-apps --create-namespace \
  --set replicaCount=2 --set service.type=NodePort --set service.nodePort=30880 --wait
