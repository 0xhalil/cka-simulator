Flow: key + CSR (openssl) → `CertificateSigningRequest` object → approve → get the certificate from `status.certificate` → kubeconfig → RBAC.
Kubernetes has no "user" object: the username is the certificate's **CN**, the groups are its **O** fields.

```bash
ssh cka-cp1
cd /opt/course/s07-csr
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -subj "/O=s07-devs/CN=jane" -out jane.csr
```
```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: s07-jane
spec:
  request: <base64 -w0 < jane.csr>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400          # 24h
  usages: ["client auth"]
```
```bash
k apply -f csr.yaml
k certificate approve s07-jane
k get csr s07-intruder -o jsonpath='{.spec.request}' | base64 -d | openssl req -noout -subject
#   O = kubeadm:cluster-admins  -> ClusterRoleBinding kubeadm:cluster-admins = cluster-admin!
k certificate deny s07-intruder
k get csr s07-jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt

K="kubectl --kubeconfig jane.kubeconfig"
$K config set-cluster cluster1 --server=https://192.168.104.6:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs
$K config set-credentials jane --client-certificate=jane.crt --client-key=jane.key --embed-certs
$K config set-context jane@cluster1 --cluster=cluster1 --user=jane
$K config use-context jane@cluster1

k -n s07-dev create role developer --verb=get,list,watch --resource=pods
k -n s07-dev edit role developer     # pods/log [get] + deployments(apps) [get,list,create,update]
k -n s07-dev create rolebinding developer --role=developer --group=s07-devs
$K -n s07-dev get pods
$K auth whoami
```

Traps:
- With the wrong `signerName` (e.g. `kubelet-serving`) no certificate is issued / client auth doesn't work.
- Without `--embed-certs` the kubeconfig contains file paths.
- The binding must target **Group** `s07-devs` (the O field) — not just User `jane`.
- `pods/log` is a separate subresource; `pods` permission doesn't cover reading logs.
