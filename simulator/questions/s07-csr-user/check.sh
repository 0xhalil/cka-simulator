D=/opt/course/s07-csr
KC() { timeout 20 kubectl --kubeconfig $D/jane.kubeconfig --request-timeout=8s "$@" </dev/null; }
cond() { kubectl get csr "$1" -o jsonpath="{.status.conditions[?(@.type==\"$2\")].status}" 2>/dev/null; }
asj() { kubectl auth can-i "$@" -n s07-dev --as=someone-else --as-group=s07-devs 2>/dev/null | grep -qx yes; }
check "jane.key is a 2048-bit RSA key" 'openssl rsa -in $D/jane.key -noout -text 2>/dev/null | grep -q "Private-Key: (2048 bit"'
check "CSR s07-jane uses signer kubernetes.io/kube-apiserver-client and is approved" '[ "$(jp csr s07-jane "{.spec.signerName}")" = kubernetes.io/kube-apiserver-client ] && [ "$(cond s07-jane Approved)" = True ]'
check "CSR s07-jane requests CN=jane, O=s07-devs" 'jp csr s07-jane "{.spec.request}" | base64 -d | openssl req -noout -subject -nameopt compat | grep -Eq "/O=s07-devs/CN=jane$|O=s07-devs, *CN=jane"'
check "issued certificate valid for 24h" 'jp csr s07-jane "{.status.certificate}" | base64 -d > /tmp/s07j.crt && s=$(date -d "$(openssl x509 -in /tmp/s07j.crt -noout -startdate | cut -d= -f2)" +%s) && e=$(date -d "$(openssl x509 -in /tmp/s07j.crt -noout -enddate | cut -d= -f2)" +%s) && [ $((e-s)) -ge 85000 ] && [ $((e-s)) -le 87000 ]'
check "jane.crt is the issued certificate and matches jane.key" '[ -s $D/jane.crt ] && [ -s /tmp/s07j.crt ] && cmp -s <(openssl x509 -in $D/jane.crt -noout -modulus) <(openssl rsa -in $D/jane.key -noout -modulus 2>/dev/null) && cmp -s <(openssl x509 -in $D/jane.crt -noout -fingerprint) <(openssl x509 -in /tmp/s07j.crt -noout -fingerprint)'
check "CSR s07-intruder is denied (not approved)" '[ "$(cond s07-intruder Denied)" = True ] && [ -z "$(cond s07-intruder Approved)" ]'
check "kubeconfig: current context jane@cluster1, cluster cluster1, user jane" '[ "$(KC config current-context)" = jane@cluster1 ] && [ "$(KC config view -o jsonpath="{.contexts[?(@.name==\"jane@cluster1\")].context.cluster}:{.contexts[?(@.name==\"jane@cluster1\")].context.user}")" = cluster1:jane ]'
check "kubeconfig embeds CA, client cert and key" 'grep -q certificate-authority-data: $D/jane.kubeconfig && grep -q client-certificate-data: $D/jane.kubeconfig && grep -q client-key-data: $D/jane.kubeconfig && ! grep -Eq "^ *(certificate-authority|client-certificate|client-key):" $D/jane.kubeconfig'
check "kubeconfig authenticates as jane (group s07-devs)" 'KC auth whoami -o jsonpath="{.status.userInfo.username} {.status.userInfo.groups}" | grep -q "^jane .*s07-devs"'
check "jane can list pods and read logs in s07-dev" 'KC -n s07-dev get pods web && KC -n s07-dev auth can-i get pods --subresource=log | grep -qx yes'
check "Role developer grants deployments get/list/create/update" 'for v in get list create update; do KC -n s07-dev auth can-i $v deployments.apps | grep -qx yes || exit 1; done'
check "RoleBinding developer binds the Group s07-devs" '[ "$(jp rolebinding developer -n s07-dev "{.roleRef.name}")" = developer ] && asj list pods && asj create deployments.apps'
guard "jane cannot delete pods or deployments in s07-dev" '! KC -n s07-dev auth can-i delete pods | grep -qx yes && ! KC -n s07-dev auth can-i delete deployments.apps | grep -qx yes'
guard "jane has no access outside s07-dev" '! KC -n default auth can-i list pods | grep -qx yes'
rm -f /tmp/s07j.crt
