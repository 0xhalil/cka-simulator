D=/opt/course/s07-csr
cd $D
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -subj "/O=s07-devs/CN=jane" -out jane.csr
cat <<YAML | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata: {name: s07-jane}
spec:
  request: $(base64 -w0 < jane.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: [client auth]
YAML
kubectl certificate approve s07-jane
kubectl certificate deny s07-intruder
for i in $(seq 20); do C=$(kubectl get csr s07-jane -o jsonpath='{.status.certificate}'); [ -n "$C" ] && break; sleep 1; done
echo "$C" | base64 -d > jane.crt
SRV=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
K="kubectl --kubeconfig jane.kubeconfig"
rm -f jane.kubeconfig
$K config set-cluster cluster1 --server=$SRV --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs
$K config set-credentials jane --client-certificate=jane.crt --client-key=jane.key --embed-certs
$K config set-context jane@cluster1 --cluster=cluster1 --user=jane
$K config use-context jane@cluster1
cat <<'YAML' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: developer, namespace: s07-dev}
rules:
- apiGroups: [""]
  resources: [pods]
  verbs: [get, list, watch]
- apiGroups: [""]
  resources: [pods/log]
  verbs: [get]
- apiGroups: [apps]
  resources: [deployments]
  verbs: [get, list, create, update]
YAML
kubectl -n s07-dev create rolebinding developer --role=developer --group=s07-devs
chown -R candidate: $D
