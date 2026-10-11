F=/opt/course/s07-certs/answers.txt
C=/etc/kubernetes/pki/apiserver.crt
ISS=$(openssl x509 -in $C -noout -issuer | sed 's/.*CN = //')
SAN=$(openssl x509 -in $C -noout -ext subjectAltName | tail -n +2 | sed -E 's/DNS://g; s/IP Address://g; s/ //g')
END=$(openssl x509 -in $C -noout -enddate | cut -d= -f2)
ECERT=$(grep -- --etcd-certfile /etc/kubernetes/manifests/kube-apiserver.yaml | cut -d= -f2)
ECN=$(openssl x509 -in $ECERT -noout -subject | sed 's/.*CN = //')
EISS=$(openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -issuer | sed 's/.*CN = //')
W1=$(ssh -o BatchMode=yes root@cka-w1 'openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -subject' </dev/null | sed 's/^subject=//')
cat > $F <<TXT
apiserver_issuer: $ISS
apiserver_sans: $SAN
apiserver_not_after: $END
etcd_client_cert: $ECERT
etcd_client_cn: $ECN
etcd_server_issuer: $EISS
kubelet_w1_client_subject: $W1
TXT
cat $F
