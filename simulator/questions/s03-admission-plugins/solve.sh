CID=$(crictl ps --name '^kube-apiserver$' -s Running -q | head -1)
crictl exec $CID kube-apiserver -h | grep -A3 -- '--enable-admission-plugins' | tr -s ' \n' ' ' \
  | grep -oP 'default enabled ones \(\K[^)]*' | tr -d ' ' | tr ',' '\n' > /opt/course/admission/default-plugins.txt
M=/etc/kubernetes/manifests/kube-apiserver.yaml
sed -i 's#- --enable-admission-plugins=NodeRestriction$#- --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision\n    - --disable-admission-plugins=DefaultStorageClass#' $M
sleep 15
for i in $(seq 1 60); do kubectl get --raw=/readyz >/dev/null 2>&1 && break; sleep 3; done
for i in $(seq 1 20); do kubectl -n autoprov-blue create configmap autoprov-probe --from-literal=plugin=NamespaceAutoProvision && break; sleep 3; done
