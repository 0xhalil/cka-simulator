# 06 — Security

Scope: TLS & certificates, Certificates API (CSR), kubeconfig, API groups, RBAC (Role/ClusterRole), ServiceAccounts, image security (private registry), SecurityContext, NetworkPolicy, kubectx/kubens, CRD, custom controllers, operators.

---

## Q1 — Certificate inspection (4%)

*Host: `ssh controlplane`*

1. Write the **expiration date** of the kube-apiserver serving certificate into `/opt/course/1/apiserver-expiry.txt` (use `openssl`).
2. Write the command that shows the expiry of **all** kubeadm-managed certificates into `/opt/course/1/check.sh`.
3. Write all **Subject Alternative Names** of the apiserver certificate into `/opt/course/1/sans.txt`.
4. Renew only the `apiserver` certificate using kubeadm.

<details><summary>Solution</summary>

```bash
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -enddate > /opt/course/1/apiserver-expiry.txt
echo 'kubeadm certs check-expiration' > /opt/course/1/check.sh
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -ext subjectAltName > /opt/course/1/sans.txt
kubeadm certs renew apiserver
# apiserver only loads the new cert on restart:
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/ && sleep 20 && mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

The kubelet client certificate (`/var/lib/kubelet/pki/kubelet-client-current.pem`) is rotated automatically by the kubelet, not by kubeadm — `check-expiration` doesn't show it.
</details>

---

## Q2 — New user via Certificates API (7%)

Create user `jane` who can authenticate with a client certificate:

1. Generate a private key `/opt/course/2/jane.key` and a CSR with `CN=jane`, `O=dev-team`.
2. Submit a `CertificateSigningRequest` named `jane` (signer `kubernetes.io/kube-apiserver-client`, usage `client auth`, expiration 1 day) and approve it.
3. Save the signed cert to `/opt/course/2/jane.crt`.
4. Add `jane` to the kubeconfig with a context `jane@kubernetes` (cluster `kubernetes`, **embed** the certs).

<details><summary>Solution</summary>

```bash
openssl genrsa -out /opt/course/2/jane.key 2048
openssl req -new -key /opt/course/2/jane.key -subj "/CN=jane/O=dev-team" -out /opt/course/2/jane.csr
cat <<EOF | k apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata: {name: jane}
spec:
  request: $(base64 -w0 < /opt/course/2/jane.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: ["client auth"]
EOF
k certificate approve jane
k get csr jane -o jsonpath='{.status.certificate}' | base64 -d > /opt/course/2/jane.crt

k config set-credentials jane --client-key=/opt/course/2/jane.key --client-certificate=/opt/course/2/jane.crt --embed-certs=true
k config set-context jane@kubernetes --cluster=kubernetes --user=jane
k --context jane@kubernetes get pod     # Forbidden = authn OK, no authz (in Q4)
```

The group (`O=`) can be used in RBAC as `kind: Group`.
</details>

---

## Q3 — Broken kubeconfig (4%)

The kubeconfig at `/opt/course/3/kubeconfig` doesn't work: `kubectl --kubeconfig /opt/course/3/kubeconfig get nodes` fails.

1. Fix it (there are **two** problems: wrong API server port and a context referencing a non-existent user).
2. Write the name of the **current-context** and the **server URL** into `/opt/course/3/info.txt`.
3. Extract the **client certificate** of user `admin` from that kubeconfig, decode it and write its **CN** into `/opt/course/3/cn.txt`.

<details><summary>Solution</summary>

```bash
k --kubeconfig /opt/course/3/kubeconfig config view        # compare cluster/user/context names
k config view --raw -o jsonpath='{.clusters[0].cluster.server}'   # real port (usually 6443)
vim /opt/course/3/kubeconfig     # set port to 6443; match context.user to the existing user name
k --kubeconfig /opt/course/3/kubeconfig get nodes
k --kubeconfig /opt/course/3/kubeconfig config current-context
k --kubeconfig /opt/course/3/kubeconfig config view --raw -o jsonpath='{.users[?(@.name=="admin")].user.client-certificate-data}' \
  | base64 -d | openssl x509 -noout -subject > /opt/course/3/cn.txt
```
</details>

---

## Q4 — Role & RoleBinding (5%)

1. In namespace `dev`, user `jane` must be able to `get`, `list`, `watch`, `create`, `delete` **pods** and `get` **pods/log**, and **only** `update` the Deployment named `web` (no other deployments).
2. Group `dev-team` must be able to `list` **secrets** in `dev`.
3. Verify with `kubectl auth can-i` and write the output of `kubectl auth can-i update deploy/api -n dev --as jane` into `/opt/course/4/can-i.txt`.

<details><summary>Solution</summary>

```bash
k create ns dev
k -n dev create role jane-role --verb=get,list,watch,create,delete --resource=pods $do > role.yaml
```

```yaml
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","list","watch","create","delete"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  resourceNames: ["web"]
  verbs: ["update"]
```

```bash
k apply -f role.yaml
k -n dev create rolebinding jane-rb --role=jane-role --user=jane
k -n dev create role secret-lister --verb=list --resource=secrets
k -n dev create rolebinding devteam-rb --role=secret-lister --group=dev-team
k auth can-i update deploy/web -n dev --as jane                 # yes
k auth can-i update deploy/api -n dev --as jane > /opt/course/4/can-i.txt   # no
k auth can-i list secrets -n dev --as x --as-group dev-team     # yes
```

`resourceNames` doesn't work meaningfully with `list`/`watch`/`create` (on create the name doesn't exist yet).
</details>

---

## Q5 — ClusterRole for cluster-scoped resources (5%)

1. Create ClusterRole `storage-admin` that allows **all verbs** on `persistentvolumes` and `storageclasses`, and `get,list` on `nodes`.
2. Bind it to user `michelle` cluster-wide.
3. Create ClusterRole `pod-reader` (get/list pods) and give ServiceAccount `auditor` in namespace `audit` this permission **only in namespaces `dev` and `prod`** — reuse the ClusterRole, don't create Roles.

<details><summary>Solution</summary>

```bash
k create clusterrole storage-admin --verb='*' --resource=persistentvolumes,storageclasses.storage.k8s.io $do > cr.yaml
# add the nodes rule:
#  - apiGroups: [""]
#    resources: ["nodes"]
#    verbs: ["get","list"]
k apply -f cr.yaml
k create clusterrolebinding michelle-storage --clusterrole=storage-admin --user=michelle
k auth can-i create sc --as michelle; k auth can-i list nodes --as michelle

k create ns audit; k -n audit create sa auditor
k create clusterrole pod-reader --verb=get,list --resource=pods
k -n dev  create rolebinding auditor-pods --clusterrole=pod-reader --serviceaccount=audit:auditor
k -n prod create rolebinding auditor-pods --clusterrole=pod-reader --serviceaccount=audit:auditor
k auth can-i list pods -n prod --as system:serviceaccount:audit:auditor     # yes
k auth can-i list pods -n default --as system:serviceaccount:audit:auditor  # no
```

ClusterRole + RoleBinding = valid only in that namespace. This is a favorite CKA pattern.
</details>

---

## Q6 — ServiceAccount usage & token (5%)

1. Create ServiceAccount `deployer` in namespace `ci`. It must be able to `create`, `get`, `list`, `patch` deployments in `ci`.
2. Create Pod `ci-runner` (image `bitnami/kubectl`, command `sleep 1d`) running as that SA.
3. From inside the pod, list deployments in `ci` — save the output to `/opt/course/6/from-pod.txt`.
4. Create a long-lived token Secret `deployer-token` for the SA (type `kubernetes.io/service-account-token`) and write the decoded token to `/opt/course/6/token`.
5. Create Pod `no-token` (image `nginx`) using SA `deployer` that does **not** get any API token mounted.

<details><summary>Solution</summary>

```bash
k create ns ci; k -n ci create sa deployer
k -n ci create role deployer --verb=create,get,list,patch --resource=deployments.apps
k -n ci create rolebinding deployer --role=deployer --serviceaccount=ci:deployer
k -n ci run ci-runner --image=bitnami/kubectl --overrides='{"spec":{"serviceAccountName":"deployer"}}' --command -- sleep 1d
k -n ci exec ci-runner -- kubectl get deploy > /opt/course/6/from-pod.txt
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: deployer-token
  namespace: ci
  annotations:
    kubernetes.io/service-account.name: deployer
type: kubernetes.io/service-account-token
```

```bash
k apply -f tok.yaml
k -n ci get secret deployer-token -o jsonpath='{.data.token}' | base64 -d > /opt/course/6/token
# short-lived alternative: k -n ci create token deployer --duration=1h
```

```yaml
spec:
  serviceAccountName: deployer
  automountServiceAccountToken: false
  containers: [{name: no-token, image: nginx}]
```
</details>

---

## Q7 — Private registry (3%)

Deployment `internal-app` in namespace `default` fails with `ImagePullBackOff` — it pulls from `myregistry.local:5000/app:1.0`, which needs authentication (user `ci`, password `ci-pass`).

Create a docker-registry Secret `regcred` and configure the Deployment to use it.

<details><summary>Solution</summary>

```bash
k create secret docker-registry regcred --docker-server=myregistry.local:5000 --docker-username=ci --docker-password=ci-pass
k patch deploy internal-app -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}'
k rollout status deploy internal-app
```

Alternative: add it to the SA's `imagePullSecrets` field — all pods using that SA get it automatically.
</details>

---

## Q8 — SecurityContext (5%)

Create Pod `secure-app` in namespace `default` (image `busybox:1.36`, command `sleep 1d`) such that:

- All containers run as **user 1000**, **group 3000**, and files in volumes are owned by **fsGroup 2000**.
- The container **cannot escalate privileges**, has a **read-only root filesystem**, drops **ALL** capabilities and adds only `NET_BIND_SERVICE`.
- An `emptyDir` is mounted at `/data` so the app can still write there.

Verify with `id` and by writing to `/` (must fail) and `/data` (must succeed).

<details><summary>Solution</summary>

```yaml
apiVersion: v1
kind: Pod
metadata: {name: secure-app}
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  volumes: [{name: data, emptyDir: {}}]
  containers:
  - name: app
    image: busybox:1.36
    command: ["sleep", "1d"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
    volumeMounts: [{name: data, mountPath: /data}]
```

```bash
k exec secure-app -- id                       # uid=1000 gid=3000 groups=2000
k exec secure-app -- touch /x                 # Read-only file system
k exec secure-app -- sh -c 'touch /data/x && ls -l /data'
```

`capabilities` and `readOnlyRootFilesystem` exist only at **container** level, `fsGroup` only at **pod** level. Container-level `runAsUser` overrides the pod level.
</details>

---

## Q9 — NetworkPolicy: lock down a tier (7%)

Namespace `prod` has pods `frontend` (label `app=frontend`), `backend` (`app=backend`, port 8080) and `db` (`app=db`, port 5432). Namespace `monitoring` is labeled `kubernetes.io/metadata.name=monitoring`.

Create NetworkPolicy `backend-policy` in `prod` so that `backend` pods:

- accept **ingress** only from `frontend` pods (same namespace) on TCP 8080, and from **any pod in namespace `monitoring`** on TCP 9090;
- can send **egress** only to `db` pods on TCP 5432 **and** DNS (UDP/TCP 53) to anywhere.

All other traffic to/from backend must be denied.

<details><summary>Solution</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: backend-policy, namespace: prod}
spec:
  podSelector: {matchLabels: {app: backend}}
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - podSelector: {matchLabels: {app: frontend}}
    ports: [{protocol: TCP, port: 8080}]
  - from:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: monitoring}}
    ports: [{protocol: TCP, port: 9090}]
  egress:
  - to:
    - podSelector: {matchLabels: {app: db}}
    ports: [{protocol: TCP, port: 5432}]
  - ports:
    - {protocol: UDP, port: 53}
    - {protocol: TCP, port: 53}
```

```bash
k -n prod exec frontend -- nc -zvw2 <backend-ip> 8080     # ok
k -n prod exec db -- nc -zvw2 <backend-ip> 8080           # timeout
k -n prod exec backend -- nc -zvw2 db-svc 5432            # ok (DNS must work too)
```

Classic trap: `namespaceSelector` **and** `podSelector` in the same `from` item (one `-`) = AND; separate items (two `-`) = OR. If you forget DNS in egress, service names won't resolve.
</details>

---

## Q10 — Default deny + pick the right existing policy (5%)

1. In namespace `isolated`, create a **default-deny** policy `deny-all` for all ingress **and** egress traffic.
2. Three manifests exist in `/opt/course/10/` (`np1.yaml`, `np2.yaml`, `np3.yaml`). Exactly one of them allows pods with `role=api` in `isolated` to receive traffic **only** from pods labeled `role=gateway` in namespace `edge` — not from all pods in `edge`, and not from `role=gateway` pods in other namespaces. Apply that one and write its filename into `/opt/course/10/correct.txt`.

<details><summary>Solution</summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: deny-all, namespace: isolated}
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
```

The correct one must contain this structure (both in a single `from` item):

```yaml
  ingress:
  - from:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: edge}}
      podSelector: {matchLabels: {role: gateway}}
```

The wrong ones typically have: (a) two separate `-` items (OR → all pods in edge + gateways in every namespace), (b) only `podSelector` (only gateways in the `isolated` namespace).
</details>

---

## Q11 — CRD + custom resource + operator awareness (6%)

1. Create a CustomResourceDefinition for kind `Backup` in group `ops.example.com`, version `v1`, **namespaced**, plural `backups`, short name `bk`, with a schema requiring `spec.schedule` (string) and `spec.retention` (integer, min 1, max 30).
2. Create Backup `nightly` in namespace `default` with `schedule: "0 2 * * *"`, `retention: 7`.
3. Try to create Backup `bad` with `retention: 99` — save the error into `/opt/course/11/error.txt`.
4. An operator is installed in the cluster that manages `Database` resources. Write the **API group** of the `Database` CRD and the **namespace** of the operator's controller Deployment into `/opt/course/11/operator.txt`.

<details><summary>Solution</summary>

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.ops.example.com        # <plural>.<group> required
spec:
  group: ops.example.com
  scope: Namespaced
  names:
    kind: Backup
    plural: backups
    singular: backup
    shortNames: ["bk"]
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: ["schedule", "retention"]
            properties:
              schedule: {type: string}
              retention: {type: integer, minimum: 1, maximum: 30}
```

```bash
k apply -f crd.yaml && k api-resources | grep backups
cat <<EOF | k apply -f -
apiVersion: ops.example.com/v1
kind: Backup
metadata: {name: nightly}
spec: {schedule: "0 2 * * *", retention: 7}
EOF
cat <<EOF | k apply -f - 2> /opt/course/11/error.txt
apiVersion: ops.example.com/v1
kind: Backup
metadata: {name: bad}
spec: {schedule: "0 2 * * *", retention: 99}
EOF
k get bk

k get crd | grep -i database
k get crd <name> -o jsonpath='{.spec.group}'
k get deploy -A | grep -i operator
```
</details>
