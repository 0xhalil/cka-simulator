Reconfigure the **kube-apiserver** of the cluster on `cka-cp2` (kubeadm, static Pod):

1. Write all admission plugins that this kube-apiserver version enables **by default** into `/opt/course/admission/default-plugins.txt`, **one plugin name per line**. Use the kube-apiserver binary itself as the source of truth.
2. Enable the admission plugin `NamespaceAutoProvision` in addition to the plugins that are already enabled explicitly.
3. Disable the admission plugin `DefaultStorageClass` (it is enabled by default).
4. Prove that it works: create a ConfigMap `autoprov-probe` with the literal `plugin=NamespaceAutoProvision` in the namespace `autoprov-blue`. The namespace does not exist and must **not** be created manually.

The API server must be healthy afterwards.
