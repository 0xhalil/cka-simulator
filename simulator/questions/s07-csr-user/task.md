A new developer, **jane**, needs access to namespace `s07-dev` on **cluster1**. All files go to `/opt/course/s07-csr/`.

1. Create a 2048-bit RSA private key `jane.key` and a certificate signing request `jane.csr` with common name **`jane`** and organization **`s07-devs`**.
2. Submit it to Kubernetes as a CertificateSigningRequest named **`s07-jane`** that will be signed by the signer which issues **client certificates for the kube-apiserver**. The certificate must be valid for **24 hours**. Approve it and save the issued certificate (PEM) as `jane.crt`.
3. Another CSR, `s07-intruder`, is pending in the cluster. Inspect it and **deny** it if it requests elevated privileges.
4. Create a kubeconfig file `jane.kubeconfig` that contains a cluster `cluster1` (the cluster1 API server, CA embedded), a user `jane` and a context `jane@cluster1`, which must be the current context. All certificates and keys must be **embedded** in the file (no file references).
5. Create a Role `developer` in namespace `s07-dev` that allows `get`, `list`, `watch` on `pods` and `get` on the pod logs, and `get`, `list`, `create`, `update` on `deployments`. Bind it with a RoleBinding `developer` so that **every member of the organization `s07-devs`** gets these permissions (not just jane).

Verify: `kubectl --kubeconfig /opt/course/s07-csr/jane.kubeconfig -n s07-dev get pods` must work.
