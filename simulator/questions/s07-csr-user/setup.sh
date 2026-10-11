course_dir s07-csr
kubectl delete csr s07-jane s07-intruder --ignore-not-found >/dev/null
reset_ns s07-dev
kubectl -n s07-dev run web --image=nginx:1.27-alpine >/dev/null
T=$(mktemp -d)
openssl genrsa -out $T/i.key 2048 2>/dev/null
openssl req -new -key $T/i.key -subj "/O=kubeadm:cluster-admins/CN=intruder" -out $T/i.csr 2>/dev/null
cat <<YAML | kubectl apply -f - >/dev/null
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata: {name: s07-intruder}
spec:
  request: $(base64 -w0 < $T/i.csr)
  signerName: kubernetes.io/kube-apiserver-client
  usages: [client auth]
YAML
rm -rf $T
chown -R candidate: /opt/course/s07-csr
