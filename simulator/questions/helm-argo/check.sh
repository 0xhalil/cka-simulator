F=/opt/course/helm/argo-helm.yaml
repo_ok() { for u in root candidate; do sudo -u $u -H helm repo list -o json 2>/dev/null | grep -q "\"name\":\"$1\",\"url\":\"$2\"" && return 0; done; return 1; }
check "repo 'argo' added with the correct URL" "repo_ok argo https://argoproj.github.io/argo-helm"
check "template file exists and was rendered from argo-cd 10.9.5" "grep -q 'helm.sh/chart: argo-cd-10.9.5' $F"
check "template rendered for namespace argocd" "grep -Eq '^  namespace: \"?argocd\"?' $F"
check "template contains no CustomResourceDefinitions" "test -s $F && ! grep -q '^kind: CustomResourceDefinition' $F"
guard "Argo CD was not installed" "! kubectl get ns argocd && ! kubectl get crd applications.argoproj.io"
check "release demo deployed in helm-apps from podinfo-6.14.1" "helm -n helm-apps list -o json | grep -q '\"name\":\"demo\".*\"status\":\"deployed\",\"chart\":\"podinfo-6.14.1\"'"
check "demo runs 2 ready replicas" "[ \"\$(kubectl -n helm-apps get deploy -o jsonpath='{.items[?(@.metadata.annotations.meta\\.helm\\.sh/release-name==\"demo\")].status.readyReplicas}')\" = 2 ]"
check "Service is NodePort 30880" "kubectl -n helm-apps get svc -o jsonpath='{range .items[?(@.metadata.annotations.meta\\.helm\\.sh/release-name==\"demo\")]}{.spec.type}:{.spec.ports[0].nodePort}{end}' | grep -qx NodePort:30880"
