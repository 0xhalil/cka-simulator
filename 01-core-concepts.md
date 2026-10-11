# 01 — Core Concepts

Scope: cluster architecture, etcd, kube-apiserver / controller-manager / scheduler / kubelet / kube-proxy, Pods, ReplicaSets, Deployments, Services, Namespaces, imperative commands, `kubectl explain`, `kubectl apply`.

---

## Q1 — Control plane inventory (4%)

*Host: `ssh controlplane`*

Find out how each control plane component and the DNS application is installed/started on the controlplane node. Write the findings into `/opt/course/1/control-plane-components.txt` in this format:

```
kubelet: [TYPE]
kube-apiserver: [TYPE]
kube-scheduler: [TYPE]
kube-controller-manager: [TYPE]
etcd: [TYPE]
dns: [TYPE] [NAME]
```

Valid `[TYPE]` values: `not-installed`, `process`, `static-pod`, `pod`.

<details><summary>Solution</summary>

```bash
ssh controlplane
ps aux | grep kubelet              # process started by systemd
systemctl status kubelet
ls /etc/kubernetes/manifests/       # etcd, kube-apiserver, kube-controller-manager, kube-scheduler
kubectl -n kube-system get pod -o wide
kubectl -n kube-system get deploy   # coredns -> pod managed by a Deployment
```

```
kubelet: process
kube-apiserver: static-pod
kube-scheduler: static-pod
kube-controller-manager: static-pod
etcd: static-pod
dns: pod coredns
```

Tip: static pods end with `<name>-<nodeName>` and have `ownerReferences.kind: Node`.
</details>

---

## Q2 — etcd and apiserver facts (4%)

*Host: `ssh controlplane`*

Without using `etcdctl`, answer the following and write the answers into `/opt/course/2/etcd-info.txt`:

1. The path of the etcd server private key
2. The path of the etcd server certificate
3. The URL kube-apiserver uses to reach etcd
4. Whether etcd uses client certificate authentication (`--client-cert-auth`)

<details><summary>Solution</summary>

```bash
cat /etc/kubernetes/manifests/etcd.yaml | grep -E 'key-file|cert-file|client-cert-auth'
grep etcd-servers /etc/kubernetes/manifests/kube-apiserver.yaml
```

```
Server private key location: /etc/kubernetes/pki/etcd/server.key
Server certificate location: /etc/kubernetes/pki/etcd/server.crt
etcd URL used by apiserver: https://127.0.0.1:2379
Client certificate authentication: yes
```

Note: the question asks for `--key-file`, not `--peer-key-file`.
</details>

---

## Q3 — Pod with specific spec (3%)

*Context: default cluster*

In namespace `apps` (create it if missing), create a Pod named `web-probe` with:

- image `nginx:1.27-alpine`, container name `web`
- labels `tier=frontend` and `env=prod`
- container port 80
- command run so the pod is reachable and `kubectl get pod web-probe -n apps` shows `Running`

Then write the command that prints **only** the Pod's IP address into `/opt/course/3/pod-ip.sh`.

<details><summary>Solution</summary>

```bash
k create ns apps
k -n apps run web-probe --image=nginx:1.27-alpine --labels=tier=frontend,env=prod --port=80 $do > 3.yaml
# container name defaults to the pod name -> edit:
sed -i 's/- name: web-probe/- name: web/' 3.yaml   # only the one in the containers list (metadata.name must stay)
k apply -f 3.yaml
echo 'kubectl -n apps get pod web-probe -o jsonpath="{.status.podIP}"' > /opt/course/3/pod-ip.sh
bash /opt/course/3/pod-ip.sh
```
</details>

---

## Q4 — Fix a broken ReplicaSet (4%)

A ReplicaSet `rs-broken` in namespace `legacy` has been created from `/opt/course/4/rs.yaml` but it is rejected by the API server. Fix the manifest so the ReplicaSet runs **3** replicas of `busybox:1.36` running `sleep 3600`, then apply it.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs-broken
  namespace: legacy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: legacy-worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      containers:
      - name: bb
        image: busybox:1.36
        command: ["sleep 3600"]
```

<details><summary>Solution</summary>

There are two errors:
1. `selector.matchLabels` doesn't match the template labels → the API returns `selector does not match template labels`.
2. `command: ["sleep 3600"]` is a single string → the container looks for a binary named `sleep 3600`, `CrashLoopBackOff`/`StartError`.

```yaml
  template:
    metadata:
      labels:
        app: legacy-worker
    spec:
      containers:
      - name: bb
        image: busybox:1.36
        command: ["sleep", "3600"]
```

```bash
k create ns legacy 2>/dev/null; k apply -f /opt/course/4/rs.yaml
k -n legacy get rs rs-broken   # READY 3/3
```
</details>

---

## Q5 — Deployment + scale + record image (4%)

In namespace `shop`:

1. Create Deployment `checkout` with image `httpd:2.4`, **4** replicas, label `app=checkout`.
2. Update the image to `httpd:2.4.62-alpine`.
3. Scale it down to **2** replicas.
4. Write the name of the ReplicaSet that is currently **inactive** (0 replicas) into `/opt/course/5/old-rs.txt`.

<details><summary>Solution</summary>

```bash
k create ns shop
k -n shop create deploy checkout --image=httpd:2.4 --replicas=4
k -n shop set image deploy/checkout httpd=httpd:2.4.62-alpine
k -n shop rollout status deploy/checkout
k -n shop scale deploy checkout --replicas=2
k -n shop get rs -l app=checkout
k -n shop get rs -l app=checkout -o jsonpath='{range .items[?(@.spec.replicas==0)]}{.metadata.name}{"\n"}{end}' > /opt/course/5/old-rs.txt
```

Note: `create deploy` derives the container name from the image name (`httpd`).
</details>

---

## Q6 — Services: ClusterIP + NodePort (5%)

In namespace `shop`, the Deployment `checkout` from Q5 exists.

1. Expose it internally as Service `checkout-svc`, type ClusterIP, port **8080** → targetPort **80**.
2. Create a second Service `checkout-np` of type NodePort with nodePort **30080** targeting the same pods on port 80.
3. Verify from a temporary pod (`busybox`/`curlimages/curl`) that `checkout-svc.shop.svc.cluster.local:8080` returns the httpd page, and save the output of `curl` into `/opt/course/6/curl.txt`.

<details><summary>Solution</summary>

```bash
k -n shop expose deploy checkout --name=checkout-svc --port=8080 --target-port=80
k -n shop create service nodeport checkout-np --tcp=80:80 --node-port=30080 $do > np.yaml
# create service sets selector app=checkout-np! fix it:
sed -i 's/app: checkout-np/app: checkout/' np.yaml   # fixes the selector (and label)
k apply -f np.yaml
k -n shop get ep checkout-svc checkout-np         # endpoints must be populated
k run tmp --rm -i --restart=Never --image=curlimages/curl -- curl -s checkout-svc.shop.svc.cluster.local:8080 > /opt/course/6/curl.txt
```

Classic trap: `kubectl create service` derives the selector from the service name — endpoints stay empty. `expose` uses the existing selector.
</details>

---

## Q7 — Namespaces and cross-namespace DNS (3%)

Pod `db` (image `redis:7`) must run in namespace `data`. Pod `client` (image `busybox:1.36`, command `sleep 1d`) runs in namespace `default`. Create a Service `db` for the redis pod on port 6379.

Write the fully-qualified DNS name that `client` must use to reach the service into `/opt/course/7/dns.txt` and prove resolution by running `nslookup` from `client`.

<details><summary>Solution</summary>

```bash
k create ns data
k -n data run db --image=redis:7 --port=6379 --expose   # pod + service in one command
k run client --image=busybox:1.36 -- sleep 1d
echo db.data.svc.cluster.local > /opt/course/7/dns.txt
k exec client -- nslookup db.data.svc.cluster.local
```
</details>

---

## Q8 — Imperative vs declarative: kubectl apply conflict (5%)

A Deployment `api` in namespace `default` was created with `kubectl create` (no `last-applied-configuration` annotation). A teammate keeps a manifest in `/opt/course/8/api.yaml` with `replicas: 5` and image `nginx:1.27`.

1. Apply the manifest so that the live object matches it **and** it can be managed declaratively from now on.
2. Then, using `kubectl explain`, find the field under `Deployment.spec` that controls how many old ReplicaSets are retained and set it to **3** in the manifest. Re-apply.
3. Write the value of `.spec.revisionHistoryLimit` from the live object into `/opt/course/8/history.txt`.

<details><summary>Solution</summary>

```bash
k explain deploy.spec | grep -i history     # revisionHistoryLimit
# add to the manifest:  spec.revisionHistoryLimit: 3
k apply -f /opt/course/8/api.yaml           # warns but adds the annotation, that's fine
k get deploy api -o jsonpath='{.spec.revisionHistoryLimit}' > /opt/course/8/history.txt
k get deploy api -o yaml | grep last-applied
```

Applying to an object not created with `kubectl apply` gives the warning "missing last-applied-configuration annotation ... will be patched automatically"; this is normal. Alternative: `kubectl apply --server-side`.
</details>
