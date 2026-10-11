You read the certificates with **openssl**; which file is used you find from the component's config (static pod manifest / kubelet kubeconfig).

```bash
ssh cka-cp1
sudo -i
# certificate served by the apiserver: --tls-cert-file
grep -E 'tls-cert-file|etcd-certfile' /etc/kubernetes/manifests/kube-apiserver.yaml
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -text | grep -E 'Issuer|Not After|DNS'
#  Issuer: CN = kubernetes
#  DNS:cka-cp1, DNS:kubernetes, ..., IP Address:10.96.0.1, IP Address:192.168.104.6
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate

# apiserver -> etcd client certificate
openssl x509 -in /etc/kubernetes/pki/apiserver-etcd-client.crt -noout -subject   # CN = kube-apiserver-etcd-client
# etcd's server certificate (etcd manifest: --cert-file)
openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -issuer             # CN = etcd-ca

# kubelet client certificate on the worker: /etc/kubernetes/kubelet.conf -> client-certificate
ssh cka-w1 sudo grep client-certificate /etc/kubernetes/kubelet.conf
ssh cka-w1 sudo openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -subject
#  subject=O = system:nodes, CN = system:node:cka-w1
```

Traps:
- `apiserver_issuer` is **kubernetes** (cluster CA); the etcd certificates have a separate CA: **etcd-ca**.
- When connecting to etcd the apiserver uses `apiserver-etcd-client.crt`, not `apiserver.crt`.
- Don't forget the IPs in the SAN list (`10.96.0.1` = kubernetes Service ClusterIP, node IP).
- The kubelet client cert is given as a file path in `kubelet.conf` (rotation: `kubelet-client-current.pem` symlink).
