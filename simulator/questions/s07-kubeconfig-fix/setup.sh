D=/opt/course/s07-kubeconfig
course_dir s07-kubeconfig
kubectl delete clusterrolebinding s07-ops-view --ignore-not-found >/dev/null
kubectl create clusterrolebinding s07-ops-view --clusterrole=view --user=s07-ops >/dev/null
P=/etc/kubernetes/pki
openssl genrsa -out $D/ops.key 2048 2>/dev/null
openssl req -new -key $D/ops.key -subj "/O=s07-ops-team/CN=s07-ops" -out $D/ops.csr 2>/dev/null
openssl x509 -req -in $D/ops.csr -CA $P/ca.crt -CAkey $P/ca.key -CAcreateserial -CAserial /tmp/s07-ca.srl -days 30 -out $D/ops.crt 2>/dev/null
rm -f $D/ops.csr /tmp/s07-ca.srl
cp $P/ca.crt $D/ca.crt
IP=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | sed -E 's#https://([^:]+):.*#\1#')
cat > $D/ops.kubeconfig <<YAML
apiVersion: v1
kind: Config
clusters:
- name: cluster1
  cluster:
    certificate-authority: $D/ca.crt
    server: https://$IP:6444
- name: staging
  cluster:
    certificate-authority-data: $(base64 -w0 < $P/ca.crt)
    server: https://10.123.0.10:6443
users:
- name: ops-admin
  user:
    client-certificate: $D/ops.crt
    client-key: $D/ops-key.pem
- name: dev-user
  user:
    token: c3RhZ2luZy1kZXYtdG9rZW4K
contexts:
- name: ops
  context:
    cluster: cluster1
    user: ops
    namespace: default
- name: staging
  context:
    cluster: staging
    user: dev-user
current-context: staging
YAML
chown -R candidate: $D
chmod 600 $D/ops.key
