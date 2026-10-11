# 02 — Scheduling

Scope: manual scheduling, labels & selectors, taints & tolerations, nodeSelector, node affinity, resource requests/limits, LimitRange/ResourceQuota, DaemonSets, static pods, PriorityClass, multiple schedulers & scheduler profiles, admission controllers, validating/mutating admission.

---

## Q1 — Manual scheduling without the scheduler (4%)

*Host: `ssh controlplane`*

Temporarily stop the kube-scheduler (do not delete its manifest permanently). Then:

1. Create Pod `manual-1` (image `httpd:2.4-alpine`) and confirm it stays `Pending`.
2. Schedule it **manually** onto `controlplane` without using `nodeSelector`, affinity or the scheduler.
3. Restart the kube-scheduler, create Pod `manual-2` (same image) and confirm it is scheduled normally.

<details><summary>Solution</summary>

```bash
ssh controlplane
mv /etc/kubernetes/manifests/kube-scheduler.yaml /etc/kubernetes/
watch crictl ps | grep scheduler     # wait until it disappears
k run manual-1 --image=httpd:2.4-alpine
k get pod manual-1 -o wide           # Pending, NODE <none>

k get pod manual-1 -o yaml > m1.yaml
# add under spec:   nodeName: controlplane
k replace --force -f m1.yaml         # nodeName can't be changed on a running pod -> recreate

mv /etc/kubernetes/kube-scheduler.yaml /etc/kubernetes/manifests/
k -n kube-system get pod | grep scheduler
k run manual-2 --image=httpd:2.4-alpine && k get pod manual-2 -o wide
```

Alternative (without deleting the pod): POST a `Binding` object — `nodeName` is the fastest way. With `nodeName` the control-plane taint is **not** taken into account, because taints are evaluated by the scheduler.
</details>

---

## Q2 — Labels & selector queries (3%)

There are many pods in namespace `catalog`. Write commands/outputs:

1. All pods with `env=prod` **and** `tier` in (`frontend`, `api`), names only → `/opt/course/2/prod.txt`
2. Count of all objects (any type, `get all`) with label `bu=finance` across **all namespaces** → `/opt/course/2/finance-count.txt`
3. Add label `protected=true` to every pod in `catalog` that has label `tier=db`, and remove label `temp` from all pods in `catalog`.

<details><summary>Solution</summary>

```bash
k -n catalog get pod -l 'env=prod,tier in (frontend,api)' -o name > /opt/course/2/prod.txt
k get all -A -l bu=finance --no-headers | wc -l > /opt/course/2/finance-count.txt
k -n catalog label pod -l tier=db protected=true
k -n catalog label pod --all temp-
```
</details>

---

## Q3 — Taints & tolerations (5%)

1. Taint `node01` with `dedicated=gpu:NoSchedule`.
2. Create Pod `no-tol` (image `nginx`). It must **not** land on node01.
3. Create Pod `gpu-job` (image `nginx`) that **tolerates** the taint **and** is guaranteed to land on `node01` (tolerations alone don't guarantee that).
4. Find which nodes in the cluster have the effect `NoExecute` on any taint and write their names to `/opt/course/3/noexecute.txt`.

<details><summary>Solution</summary>

```bash
k taint node node01 dedicated=gpu:NoSchedule
k run no-tol --image=nginx
k run gpu-job --image=nginx $do > gpu.yaml
```

```yaml
spec:
  tolerations:
  - key: dedicated
    operator: Equal
    value: gpu
    effect: NoSchedule
  nodeSelector:
    kubernetes.io/hostname: node01
  containers: ...
```

```bash
k apply -f gpu.yaml && k get pod -o wide
k get nodes -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.taints[*].effect}{"\n"}{end}' | grep NoExecute | awk '{print $1}' > /opt/course/3/noexecute.txt
```

Concept: taint = the node "repels", toleration = the pod's permission; attraction requires nodeSelector/affinity.
</details>

---

## Q4 — Node affinity (6%)

Label `node01` with `disktype=ssd` and `node02` with `disktype=hdd`.

Create Deployment `cache` in namespace `default` (image `redis:7`, 3 replicas) such that:

- Pods **must** be scheduled on nodes with `disktype` in (`ssd`, `nvme`).
- Pods **should preferably** (weight 50) be scheduled on nodes with label `zone=eu-1`.
- If no node matches the required rule, pods must stay `Pending`.

Verify placement.

<details><summary>Solution</summary>

```bash
k label node node01 disktype=ssd; k label node node02 disktype=hdd
k create deploy cache --image=redis:7 --replicas=3 $do > cache.yaml
```

```yaml
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: disktype
                operator: In
                values: ["ssd", "nvme"]
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 50
            preference:
              matchExpressions:
              - key: zone
                operator: In
                values: ["eu-1"]
      containers: ...
```

```bash
k apply -f cache.yaml && k get pod -l app=cache -o wide   # all on node01
```

Note: multiple terms under `nodeSelectorTerms` are **OR**ed, `matchExpressions` within one term are **AND**ed.
</details>

---

## Q5 — Requests, limits, LimitRange, ResourceQuota (6%)

Namespace `team-a`:

1. Create a LimitRange `defaults` so containers without resources get **request** `cpu=100m,memory=128Mi` and **limit** `cpu=200m,memory=256Mi`; max memory per container `512Mi`.
2. Create a ResourceQuota `rq` limiting the namespace to `requests.cpu=1`, `limits.memory=2Gi`, `pods=5`.
3. Create Pod `big` with memory limit `1Gi` — it must be rejected. Save the error message into `/opt/course/5/error.txt`.
4. Create Pod `small` with no resources and verify the defaults were injected.

<details><summary>Solution</summary>

```yaml
apiVersion: v1
kind: LimitRange
metadata: {name: defaults, namespace: team-a}
spec:
  limits:
  - type: Container
    defaultRequest: {cpu: 100m, memory: 128Mi}
    default: {cpu: 200m, memory: 256Mi}
    max: {memory: 512Mi}
---
apiVersion: v1
kind: ResourceQuota
metadata: {name: rq, namespace: team-a}
spec:
  hard:
    requests.cpu: "1"
    limits.memory: 2Gi
    pods: "5"
```

```bash
k create ns team-a; k apply -f lr-rq.yaml
k -n team-a run big --image=nginx $do > big.yaml
# add containers[0].resources.limits.memory: 1Gi
k apply -f big.yaml 2> /opt/course/5/error.txt; cat /opt/course/5/error.txt
# ... maximum memory usage per Container is 512Mi, but limit is 1Gi
k -n team-a run small --image=nginx
k -n team-a get pod small -o jsonpath='{.spec.containers[0].resources}'
k -n team-a describe quota rq
```

Reminder: if the quota defines `requests.cpu`, every pod must specify a request; that's why the LimitRange default is useful.
</details>

---

## Q6 — DaemonSet on all nodes including control plane (4%)

Create DaemonSet `node-exporter` in namespace `monitoring` (image `prom/node-exporter:v1.8.2`, label `app=node-exporter`) that runs **one pod on every node including the control plane**. Requests: `cpu 10m`, `memory 20Mi`.

<details><summary>Solution</summary>

```bash
k create ns monitoring
k -n monitoring create deploy node-exporter --image=prom/node-exporter:v1.8.2 $do > ds.yaml
# change to kind: DaemonSet, remove replicas/strategy/status
```

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata: {name: node-exporter, namespace: monitoring, labels: {app: node-exporter}}
spec:
  selector: {matchLabels: {app: node-exporter}}
  template:
    metadata: {labels: {app: node-exporter}}
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.8.2
        resources: {requests: {cpu: 10m, memory: 20Mi}}
```

```bash
k apply -f ds.yaml && k -n monitoring get ds,pod -o wide   # DESIRED = number of nodes
```
</details>

---

## Q7 — Static pod on a worker node (5%)

*Host: `ssh node01`*

1. Find the static pod path configured for the kubelet on `node01`.
2. Create a static pod `static-web` there (image `nginx:1.27-alpine`, requests `cpu: 10m, memory: 20Mi`).
3. From the controlplane, create a NodePort Service `static-web-svc` on port 80 exposing that static pod. Verify via `curl <node-ip>:<nodePort>`.
4. Delete the mirror pod via `kubectl delete`. Explain (into `/opt/course/7/answer.txt`) what happens and why.

<details><summary>Solution</summary>

```bash
ssh node01
ps aux | grep kubelet | grep -o -- '--config=[^ ]*'         # /var/lib/kubelet/config.yaml
grep staticPodPath /var/lib/kubelet/config.yaml             # /etc/kubernetes/manifests
kubectl run static-web --image=nginx:1.27-alpine $do > /etc/kubernetes/manifests/static-web.yaml  # if kubectl isn't available, write the YAML by hand
# add resources.requests
exit
k get pod -o wide | grep static-web          # static-web-node01
k expose pod static-web-node01 --name=static-web-svc --type=NodePort --port=80
curl <node01-ip>:$(k get svc static-web-svc -o jsonpath='{.spec.ports[0].nodePort}')
k delete pod static-web-node01
k get pod static-web-node01                  # comes back within a few seconds
```

Answer: the mirror pod is only a reflection in the API; the kubelet watches the manifest file, so it recreates the pod. To delete it permanently, remove the manifest file on the node.

Note: `expose pod` uses the pod's labels (`run=static-web`) as the selector.
</details>

---

## Q8 — PriorityClass & preemption (6%)

1. Create PriorityClass `high-prio` with value `1000000`, `preemptionPolicy: PreemptLowerPriority`, not global default.
2. Create PriorityClass `low-prio` with value `1000`, `preemptionPolicy: Never`.
3. Namespace `batch` has Deployment `filler` (already consuming most of node01's memory via requests). Create Pod `critical` in `batch` with `priorityClassName: high-prio`, memory request large enough that it only fits if a `filler` pod is evicted, pinned to `node01`.
4. Write the names of all PriorityClasses with value > 1,000,000,000 (the system ones) into `/opt/course/8/system-pc.txt`.

<details><summary>Solution</summary>

```bash
k create priorityclass high-prio --value=1000000 --preemption-policy=PreemptLowerPriority
k create priorityclass low-prio --value=1000 --preemption-policy=Never
k -n batch run critical --image=nginx $do > crit.yaml
```

```yaml
spec:
  priorityClassName: high-prio
  nodeSelector: {kubernetes.io/hostname: node01}
  containers:
  - name: critical
    image: nginx
    resources: {requests: {memory: 1Gi}}   # adjust based on node allocatable - filler
```

```bash
k apply -f crit.yaml
k -n batch get events --sort-by=.lastTimestamp | grep -i preempt
k get pc -o jsonpath='{range .items[?(@.value>1000000000)]}{.metadata.name}{"\n"}{end}' > /opt/course/8/system-pc.txt
# system-cluster-critical, system-node-critical
```

Note: the difference between nodeSelector and `nodeName` matters — `nodeName` bypasses the scheduler, so **no** preemption happens.
</details>

---

## Q9 — Second scheduler (5%)

A second scheduler named `my-scheduler` must run as a Deployment in `kube-system` using the same image as the default kube-scheduler. A ServiceAccount `my-scheduler` with ClusterRoleBinding to `system:kube-scheduler` and `system:volume-scheduler` already exists, and a ConfigMap `my-scheduler-config` contains:

```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: my-scheduler
leaderElection:
  leaderElect: false
```

1. Create the Deployment (mount the ConfigMap at `/etc/kubernetes/my-scheduler`, run `kube-scheduler --config=/etc/kubernetes/my-scheduler/my-scheduler-config.yaml`).
2. Create Pod `custom-sched` (image `nginx`) scheduled by `my-scheduler`. Prove which scheduler scheduled it (save the event line to `/opt/course/9/event.txt`).

<details><summary>Solution</summary>

```bash
k -n kube-system get pod kube-scheduler-controlplane -o jsonpath='{.spec.containers[0].image}'
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: my-scheduler, namespace: kube-system}
spec:
  replicas: 1
  selector: {matchLabels: {app: my-scheduler}}
  template:
    metadata: {labels: {app: my-scheduler}}
    spec:
      serviceAccountName: my-scheduler
      containers:
      - name: kube-scheduler
        image: registry.k8s.io/kube-scheduler:v1.xx.x   # the image from above
        command:
        - kube-scheduler
        - --config=/etc/kubernetes/my-scheduler/my-scheduler-config.yaml
        volumeMounts:
        - {name: cfg, mountPath: /etc/kubernetes/my-scheduler}
      volumes:
      - name: cfg
        configMap: {name: my-scheduler-config}
```

The ConfigMap key name must be `my-scheduler-config.yaml` (check with `k -n kube-system describe cm my-scheduler-config`).

```bash
k run custom-sched --image=nginx $do > cs.yaml   # add spec.schedulerName: my-scheduler
k apply -f cs.yaml
k get events --field-selector involvedObject.name=custom-sched -o wide | grep Scheduled > /opt/course/9/event.txt
# SOURCE column: my-scheduler
```
</details>

---

## Q10 — Admission controllers (7%)

*Host: `ssh controlplane`*

1. Write the list of admission plugins **explicitly enabled** in the kube-apiserver manifest to `/opt/course/10/enabled.txt`.
2. Enable the `NamespaceAutoProvision` admission plugin and disable `DefaultStorageClass`.
3. Verify: creating `kubectl run x --image=nginx -n auto-ns` (namespace doesn't exist) must succeed and create the namespace.
4. Create a `ValidatingAdmissionPolicy` `replica-limit` + binding `replica-limit-binding` that **denies** any Deployment with more than 5 replicas in namespaces labeled `env=test`. Test it.

<details><summary>Solution</summary>

```bash
ssh controlplane
grep -- --enable-admission-plugins /etc/kubernetes/manifests/kube-apiserver.yaml | cut -d= -f2 | tr ',' '\n' > /opt/course/10/enabled.txt
# (enabled by default: kube-apiserver -h | grep enable-admission-plugins)
cp /etc/kubernetes/manifests/kube-apiserver.yaml ~/kube-apiserver.yaml.bak   # keep the backup OUTSIDE manifests!
vim /etc/kubernetes/manifests/kube-apiserver.yaml
#   - --enable-admission-plugins=NodeRestriction,NamespaceAutoProvision
#   - --disable-admission-plugins=DefaultStorageClass
watch crictl ps | grep apiserver
k run x --image=nginx -n auto-ns && k get ns auto-ns
```

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata: {name: replica-limit}
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments"]
  validations:
  - expression: "object.spec.replicas <= 5"
    message: "replicas must be <= 5"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata: {name: replica-limit-binding}
spec:
  policyName: replica-limit
  validationActions: [Deny]
  matchResources:
    namespaceSelector:
      matchLabels: {env: test}
```

```bash
k create ns t1; k label ns t1 env=test
k -n t1 create deploy d --image=nginx --replicas=6   # denied
k -n t1 create deploy d --image=nginx --replicas=3   # ok
```

Traps: if you leave the backup file in `/etc/kubernetes/manifests/`, the kubelet tries to run it as a static pod too. If the apiserver doesn't come up: `crictl ps -a`, `crictl logs <id>`, `/var/log/pods/kube-system_kube-apiserver*`.
</details>
