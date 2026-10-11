F=/opt/course/s07-certs/answers.txt
val() { grep -E "^$1:" $F 2>/dev/null | head -1 | cut -d: -f2- | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }
norm() { tr -d ' "' | tr ',' '\n' | sed '/^$/d' | sort; }
P=/etc/kubernetes/pki
SAN=$(openssl x509 -in $P/apiserver.crt -noout -ext subjectAltName | tail -n +2 | sed -E 's/DNS://g; s/IP Address://g')
END=$(openssl x509 -in $P/apiserver.crt -noout -enddate | cut -d= -f2)
W1=$(on cka-w1 'openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -subject -nameopt sep_comma_plus_space' | sed 's/^subject=//')
check "apiserver_issuer is correct" '[ "$(val apiserver_issuer)" = kubernetes ]'
check "apiserver_sans lists all DNS and IP SANs" '[ -n "$(val apiserver_sans)" ] && [ "$(val apiserver_sans | norm)" = "$(echo "$SAN" | norm)" ]'
check "apiserver_not_after matches the certificate expiry" 'v=$(val apiserver_not_after); [ -n "$v" ] && [ "$(date -d "$v" +%s)" = "$(date -d "$END" +%s)" ]'
check "etcd_client_cert is the apiserver etcd client certificate path" '[ "$(val etcd_client_cert)" = $P/apiserver-etcd-client.crt ]'
check "etcd_client_cn is correct" '[ "$(val etcd_client_cn)" = kube-apiserver-etcd-client ]'
check "etcd_server_issuer is correct" '[ "$(val etcd_server_issuer)" = "$(openssl x509 -in $P/etcd/server.crt -noout -issuer -nameopt multiline | sed -n "s/^ *commonName *= *//p")" ]'
check "kubelet_w1_client_subject is correct" 'v=$(val kubelet_w1_client_subject | tr -d " "); [ -n "$v" ] && [ "$v" = "$(echo "$W1" | tr -d " ")" ]'
guard "apiserver certificate still present and valid" '[ -n "$END" ] && openssl x509 -in $P/apiserver.crt -noout -checkend 0'
