Your team wants to evaluate Argo CD and deploy a small demo app using Helm.

1. Add the official Argo CD Helm repository with the name `argo`:
   `https://argoproj.github.io/argo-helm`
2. Generate a template of the Argo CD Helm chart **version `10.9.5`** for the namespace `argocd` and save it to `/opt/course/helm/argo-helm.yaml`. Configure the chart so that it does **not install CRDs**. Do not install Argo CD.
3. Add the repository `https://stefanprodan.github.io/podinfo` as `podinfo` and install chart `podinfo/podinfo` **version `6.14.1`** as release `demo` in namespace `helm-apps` (create the namespace) with:
   - `replicaCount` = `2`
   - Service of type `NodePort` with nodePort `30880`
