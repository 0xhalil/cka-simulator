Your security team needs an inventory of some of the certificates used by **cluster1**. Do **not** change, renew or move any certificate.

Fill in the file `/opt/course/s07-certs/answers.txt` (it already contains the keys). Keep the format `key: value`, one key per line:

| Key | Value |
|-----|-------|
| `apiserver_issuer` | The **CN** of the issuer of the certificate the kube-apiserver **serves** to its clients (only the CN value, e.g. `my-ca`) |
| `apiserver_sans` | All Subject Alternative Names of that certificate (DNS names **and** IP addresses), comma-separated, without `DNS:` / `IP Address:` prefixes |
| `apiserver_not_after` | The expiry date of that certificate exactly as printed by `openssl` (e.g. `Jan  1 00:00:00 2030 GMT`) |
| `etcd_client_cert` | Absolute path of the certificate file the kube-apiserver uses to authenticate **to etcd** |
| `etcd_client_cn` | The CN of that certificate |
| `etcd_server_issuer` | The CN of the issuer of the certificate **etcd** serves to its clients |
| `kubelet_w1_client_subject` | The full subject of the **client** certificate the kubelet on node `cka-w1` uses to authenticate to the apiserver, in the form `O = ..., CN = ...` |
