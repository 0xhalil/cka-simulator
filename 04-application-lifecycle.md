# 04 — Application Lifecycle Management

Scope: rolling update & rollback, deployment strategy, command/args, env, ConfigMap, Secret, encryption at rest, multi-container pod (sidecar), init container, HPA, manual scaling, in-place pod resize, VPA.

---

## Q1 — Rolling update strategy & rollback (6%)

Deployment `frontend` in namespace `web` runs `nginx:1.25` with 6 replicas.

1. Configure the rolling update so that **at most 1 pod is unavailable** and **at most 2 extra pods** are created during an update.
2. Update the image to `nginx:1.26` and annotate the change cause `"upgrade to 1.26"` (it must appear in `rollout history`).
3. Update the image to `nginx:1.99-doesnotexist`. The rollout gets stuck.
4. Roll back to the revision running `nginx:1.26` (**not** necessarily "previous"). Write that revision number to `/opt/course/1/revision.txt`.

<details><summary>Solution</summary>

```bash
k -n web patch deploy frontend -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxUnavailable":1,"maxSurge":2}}}}'
k -n web set image deploy/frontend nginx=nginx:1.26
k -n web annotate deploy frontend kubernetes.io/change-cause="upgrade to 1.26" --overwrite
k -n web rollout status deploy frontend
k -n web set image deploy/frontend nginx=nginx:1.99-doesnotexist
k -n web rollout history deploy frontend
k -n web rollout history deploy frontend --revision=<N>     # verify the image
k -n web rollout undo deploy frontend --to-revision=<N>
echo <N> > /opt/course/1/revision.txt
```

Note: the rolled-back revision gets a new number (the old number disappears from history).
The container name may differ: `k -n web get deploy frontend -o jsonpath='{.spec.template.spec.containers[*].name}'`.
</details>

---

## Q2 — Recreate strategy (2%)

Change Deployment `legacy-db` in namespace `web` to use the `Recreate` strategy (it currently has a `rollingUpdate` block). Apply an image change to `postgres:16` and confirm that **all old pods are terminated before new ones start**.

<details><summary>Solution</summary>

```bash
k -n web edit deploy legacy-db
#  strategy:
#    type: Recreate       # DELETE the rollingUpdate block, otherwise validation error
k -n web set image deploy/legacy-db postgres=postgres:16
k -n web get pod -w
```
</details>

---

## Q3 — Command & args override (3%)

Image `busybox:1.36`. Create Pod `ticker` in namespace `default` that runs:

```
sh -c 'while true; do echo "$(date) tick $INTERVAL"; sleep $INTERVAL; done'
```

using **`command`** for `sh -c` and **`args`** for the script, with env var `INTERVAL=5`. Then answer in `/opt/course/3/answer.txt`: which Docker instruction does Kubernetes' `args` override — `ENTRYPOINT` or `CMD`?

<details><summary>Solution</summary>

```yaml
apiVersion: v1
kind: Pod
metadata: {name: ticker}
spec:
  containers:
  - name: ticker
    image: busybox:1.36
    env:
    - {name: INTERVAL, value: "5"}
    command: ["sh", "-c"]
    args: ['while true; do echo "$(date) tick $INTERVAL"; sleep $INTERVAL; done']
```

```bash
k apply -f ticker.yaml && k logs ticker
echo CMD > /opt/course/3/answer.txt     # command -> ENTRYPOINT, args -> CMD
```
</details>

---

## Q4 — ConfigMap: env + volume + single key (6%)

Namespace `cfg`:

1. Create ConfigMap `app-config` from literal `LOG_LEVEL=debug`, literal `MODE=prod` and file `/opt/course/4/nginx.conf` (key must be `nginx.conf`).
2. Create Pod `cfg-pod` (image `nginx:1.27`) that:
   - gets **all** literal keys as env vars,
   - gets `MODE` additionally as env var `APP_MODE`,
   - mounts **only** `nginx.conf` at `/etc/nginx/conf.d/default.conf` **without hiding** the other files in `/etc/nginx/conf.d/`.

<details><summary>Solution</summary>

```bash
k create ns cfg
k -n cfg create cm app-config --from-literal=LOG_LEVEL=debug --from-literal=MODE=prod --from-file=/opt/course/4/nginx.conf
```

```yaml
apiVersion: v1
kind: Pod
metadata: {name: cfg-pod, namespace: cfg}
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    envFrom:
    - configMapRef: {name: app-config}      # in older versions "nginx.conf" is an invalid env name -> skipped; with v1.34+ relaxed validation it also comes in as env (harmless)
    env:
    - name: APP_MODE
      valueFrom: {configMapKeyRef: {name: app-config, key: MODE}}
    volumeMounts:
    - name: conf
      mountPath: /etc/nginx/conf.d/default.conf
      subPath: nginx.conf
  volumes:
  - name: conf
    configMap: {name: app-config}
```

```bash
k -n cfg exec cfg-pod -- env | grep -E 'LOG_LEVEL|MODE'
k -n cfg exec cfg-pod -- ls /etc/nginx/conf.d/
```

A file mounted with `subPath` is **not updated automatically** when the ConfigMap changes.
</details>

---

## Q5 — Secrets + decode (4%)

1. Create a generic Secret `db-cred` in namespace `cfg` with `username=admin` and `password=S3cr3t!`.
2. Mount it read-only into Pod `db-client` (image `busybox:1.36`, `sleep 1d`) at `/etc/db`, and expose `password` as env var `DB_PASS`.
3. A Secret `legacy-token` already exists in `kube-system`. Write its decoded `token` value into `/opt/course/5/token.txt`.

<details><summary>Solution</summary>

```bash
k -n cfg create secret generic db-cred --from-literal=username=admin --from-literal='password=S3cr3t!'
```

```yaml
spec:
  containers:
  - name: db-client
    image: busybox:1.36
    command: ["sleep", "1d"]
    env:
    - name: DB_PASS
      valueFrom: {secretKeyRef: {name: db-cred, key: password}}
    volumeMounts:
    - {name: s, mountPath: /etc/db, readOnly: true}
  volumes:
  - name: s
    secret: {secretName: db-cred}
```

```bash
k -n kube-system get secret legacy-token -o jsonpath='{.data.token}' | base64 -d > /opt/course/5/token.txt
```

In Bash `!` triggers history expansion — use single quotes.
</details>

---

## Q6 — Encrypt Secrets at rest (8%)

*Host: `ssh controlplane`*

1. Configure kube-apiserver to encrypt **Secrets** in etcd using `aescbc` with key name `key1` (generate a random 32-byte key). Keep `identity` as fallback so existing data stays readable. Put the config at `/etc/kubernetes/enc/enc.yaml`.
2. Make sure **all existing** Secrets are re-written encrypted.
3. Prove it: read secret `db-cred` (ns `cfg`) directly from etcd with `etcdctl` and save the hexdump to `/opt/course/6/etcd-dump.txt` — it must start with `k8s:enc:aescbc:v1:key1`.

<details><summary>Solution</summary>

```bash
mkdir -p /etc/kubernetes/enc
head -c 32 /dev/urandom | base64
```

```yaml
# /etc/kubernetes/enc/enc.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: ["secrets"]
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: <BASE64_KEY>
  - identity: {}
```

kube-apiserver manifest:

```yaml
    - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml
    volumeMounts:
    - {name: enc, mountPath: /etc/kubernetes/enc, readOnly: true}
  volumes:
  - name: enc
    hostPath: {path: /etc/kubernetes/enc, type: DirectoryOrCreate}
```

```bash
watch crictl ps | grep apiserver
k get secrets -A -o json | k replace -f -       # rewrite existing secrets
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/cfg/db-cred | hexdump -C > /opt/course/6/etcd-dump.txt
head /opt/course/6/etcd-dump.txt
```

Provider order is critical: the **first** provider is used for writing. If `identity` is first, nothing gets encrypted.
</details>

---

## Q7 — Native sidecar + init container (7%)

Create Pod `log-shipper` in namespace `default`:

- **Init container** `init-perm` (`busybox:1.36`) runs `sh -c 'mkdir -p /var/log/app && echo init > /var/log/app/boot.log'`.
- **Native sidecar** `shipper` (`busybox:1.36`) — must start **before** the main container and keep running for the pod's lifetime — runs `tail -F /var/log/app/app.log`.
- Main container `app` (`busybox:1.36`) runs `sh -c 'while true; do date >> /var/log/app/app.log; sleep 2; done'`.
- All share an `emptyDir` volume at `/var/log/app`.

Verify `kubectl logs log-shipper -c shipper` shows timestamps.

<details><summary>Solution</summary>

```yaml
apiVersion: v1
kind: Pod
metadata: {name: log-shipper}
spec:
  volumes:
  - {name: logs, emptyDir: {}}
  initContainers:
  - name: init-perm
    image: busybox:1.36
    command: ["sh", "-c", "mkdir -p /var/log/app && echo init > /var/log/app/boot.log"]
    volumeMounts: [{name: logs, mountPath: /var/log/app}]
  - name: shipper
    image: busybox:1.36
    restartPolicy: Always          # <- this is what makes it a native sidecar
    command: ["tail", "-F", "/var/log/app/app.log"]
    volumeMounts: [{name: logs, mountPath: /var/log/app}]
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /var/log/app/app.log; sleep 2; done"]
    volumeMounts: [{name: logs, mountPath: /var/log/app}]
```

```bash
k apply -f ls.yaml && k get pod log-shipper   # READY 2/2
k logs log-shipper -c shipper
```

Order matters: init containers run in list order; the sidecar starts after `init-perm` finishes.
</details>

---

## Q8 — HorizontalPodAutoscaler (5%)

Deployment `php-apache` in namespace `scale` exists (requests `cpu: 200m`).

1. Create HPA `php-apache` (`autoscaling/v2`) targeting **50% average CPU utilization**, min 2, max 8 replicas.
2. Configure **scale-down** behavior: stabilization window **60s**, and remove at most **1 pod per 30s**.
3. Write the HPA's current target/metric value line (from `kubectl get hpa`) into `/opt/course/8/hpa.txt`.

<details><summary>Solution</summary>

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: {name: php-apache, namespace: scale}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: cpu
      target: {type: Utilization, averageUtilization: 50}
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 60
      policies:
      - {type: Pods, value: 1, periodSeconds: 30}
```

```bash
k apply -f hpa.yaml   # or quick skeleton: k -n scale autoscale deploy php-apache --cpu-percent=50 --min=2 --max=8
k -n scale get hpa php-apache --no-headers > /opt/course/8/hpa.txt
```

If you see `<unknown>/50%`: metrics-server is missing or the pods have no CPU request defined.
</details>

---

## Q9 — In-place pod resize & VPA (7%)

1. Pod `resizer` in namespace `scale` (image `nginx`, requests `cpu: 100m, memory: 64Mi`, limits `cpu: 200m, memory: 128Mi`) is running. Configure its container so that **CPU changes don't restart the container** but **memory changes do** — this must be set at creation, so recreate the pod accordingly.
2. Increase CPU request to `300m` and CPU limit to `400m` **in place** (the pod must not be recreated; restart count must stay 0).
3. The VPA CRDs and components are installed. Create a VPA `php-vpa` for Deployment `php-apache` in namespace `scale` in **recommendation-only** mode. Write the recommended CPU **target** into `/opt/course/9/vpa.txt` once it is available.

<details><summary>Solution</summary>

```yaml
spec:
  containers:
  - name: resizer
    image: nginx
    resizePolicy:
    - {resourceName: cpu, restartPolicy: NotRequired}
    - {resourceName: memory, restartPolicy: RestartContainer}
    resources:
      requests: {cpu: 100m, memory: 64Mi}
      limits: {cpu: 200m, memory: 128Mi}
```

```bash
k replace --force -f resizer.yaml
k -n scale patch pod resizer --subresource resize --patch \
  '{"spec":{"containers":[{"name":"resizer","resources":{"requests":{"cpu":"300m"},"limits":{"cpu":"400m"}}}]}}'
k -n scale get pod resizer -o jsonpath='{.spec.containers[0].resources}{"\n"}{.status.containerStatuses[0].restartCount}'
```

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata: {name: php-vpa, namespace: scale}
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  updatePolicy:
    updateMode: "Off"
```

```bash
k apply -f vpa.yaml
k -n scale get vpa php-vpa -o jsonpath='{.status.recommendation.containerRecommendations[0].target.cpu}' > /opt/course/9/vpa.txt
```

Note: `--subresource resize` requires kubectl v1.32+. The QoS class can't change via resize (Guaranteed → Burstable is not possible).
</details>
