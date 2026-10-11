```bash
ssh cka-cp2
sudo -i
# 1) default plugin list: the binary's help output (from inside the container)
crictl exec $(crictl ps --name kube-apiserver -q) kube-apiserver -h | grep -A3 enable-admission-plugins
#   ... in addition to default enabled ones (NamespaceLifecycle, LimitRanger, ...)
crictl exec $(crictl ps --name kube-apiserver -q) kube-apiserver -h | grep -A3 -- '--enable-admission-plugins' \
  | tr -s ' \n' ' ' | grep -oP 'default enabled ones \(\K[^)]*' | tr -d ' ' | tr ',' '\n' \
  > /opt/course/admission/default-plugins.txt
# 2+3) manifest
vim /etc/kubernetes/manifests/kube-apiserver.yaml
    - --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
    - --disable-admission-plugins=DefaultStorageClass
watch crictl ps                       # new kube-apiserver container
ps -ef | grep [k]ube-apiserver | tr ' ' '\n' | grep admission
# 4)
kubectl -n autoprov-blue create configmap autoprov-probe --from-literal=plugin=NamespaceAutoProvision
kubectl get ns autoprov-blue          # created automatically
```

Traps: `NodeRestriction` must not be removed (you **append** to the list). The default list is shown by `kube-apiserver -h`; in a kubeadm cluster the binary only exists inside the container (`crictl exec` or `kubectl -n kube-system exec kube-apiserver-cka-cp2 -- kube-apiserver -h`). Note: NamespaceAutoProvision/NamespaceExists are deprecated but still usable.

