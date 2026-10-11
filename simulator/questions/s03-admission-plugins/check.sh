for i in $(seq 1 30); do kubectl get --raw=/readyz >/dev/null 2>&1 && break; sleep 3; done
ARGS=$(tr '\0' '\n' < /proc/$(pgrep -xo kube-apiserver)/cmdline 2>/dev/null)
EN=$(echo "$ARGS" | sed -n 's/^--enable-admission-plugins=//p' | tr ',' '\n')
DIS=$(echo "$ARGS" | sed -n 's/^--disable-admission-plugins=//p' | tr ',' '\n')
CID=$(crictl ps --name '^kube-apiserver$' -s Running -q | head -1)
DEF=$(crictl exec $CID kube-apiserver -h 2>&1 | tr -s ' \n' ' ' | grep -oP -- '--enable-admission-plugins strings admission plugins that should be enabled in addition to default enabled ones \(\K[^)]*' | tr -d ' ' | tr ',' '\n' | sort)
F=/opt/course/admission/default-plugins.txt
check "default-plugins.txt lists exactly the default admission plugins" "[ -n \"\$DEF\" ] && [ \"\$(tr -d ' \r' < $F | grep . | sort -u)\" = \"\$DEF\" ]"
check "running kube-apiserver enables NamespaceAutoProvision" "echo \"\$EN\" | grep -qx NamespaceAutoProvision"
check "running kube-apiserver disables DefaultStorageClass" "echo \"\$DIS\" | grep -qx DefaultStorageClass"
check "a PVC without storageClassName no longer gets the default StorageClass" "[ -z \"\$(printf 'apiVersion: v1\nkind: PersistentVolumeClaim\nmetadata: {name: adm-chk, namespace: default}\nspec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 1Mi}}}\n' | kubectl create --dry-run=server -f - -o jsonpath='{.spec.storageClassName}')\" ] && kubectl get sc -o jsonpath='{.items[*].metadata.annotations}' | grep -q is-default-class"
check "ConfigMap autoprov-probe (plugin=NamespaceAutoProvision) exists in auto-created namespace autoprov-blue" "[ \"\$(jp cm autoprov-probe -n autoprov-blue '{.data.plugin}')\" = NamespaceAutoProvision ]"
guard "NodeRestriction is still enabled" "echo \"\$EN\" | grep -qx NodeRestriction"
guard "kube-apiserver is healthy" "kubectl get --raw=/readyz"
