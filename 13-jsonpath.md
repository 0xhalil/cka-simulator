# 13 — Other Topics: JSONPath & Advanced kubectl

Scope: `-o jsonpath`, `range`, filters, `-o custom-columns`, `--sort-by`, `--field-selector`.

---

## Q1 — Node info (3%)

Write the following into the given files using **one kubectl command each**:

1. Names of all nodes, space-separated, one line → `/opt/course/1/nodes.txt`
2. Each node's name and **InternalIP**, tab-separated, one per line → `/opt/course/1/node-ips.txt`
3. The OS image of all nodes → `/opt/course/1/os.txt`

<details><summary>Solution</summary>

```bash
k get nodes -o jsonpath='{.items[*].metadata.name}' > /opt/course/1/nodes.txt
k get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' > /opt/course/1/node-ips.txt
k get nodes -o jsonpath='{.items[*].status.nodeInfo.osImage}' > /opt/course/1/os.txt
```
</details>

---

## Q2 — custom-columns + sort (4%)

Write a command into `/opt/course/2/pv.sh` that lists all PersistentVolumes **sorted by capacity** with columns `NAME` and `CAPACITY`. Save its output into `/opt/course/2/pv.txt`.

<details><summary>Solution</summary>

```bash
echo "kubectl get pv --sort-by=.spec.capacity.storage -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage" > /opt/course/2/pv.sh
bash /opt/course/2/pv.sh > /opt/course/2/pv.txt
```
</details>

---

## Q3 — kubeconfig queries (3%)

Using kubeconfig `/root/my-kube-config`:

1. Write the context name whose user is `aws-user` into `/opt/course/3/context.txt`.
2. Write all user names into `/opt/course/3/users.txt`.

<details><summary>Solution</summary>

```bash
k config view --kubeconfig=/root/my-kube-config -o jsonpath='{.contexts[?(@.context.user=="aws-user")].name}' > /opt/course/3/context.txt
k config view --kubeconfig=/root/my-kube-config -o jsonpath='{.users[*].name}' > /opt/course/3/users.txt
```
</details>

---

## Q4 — Pods & images report (5%)

Across all namespaces, write a report into `/opt/course/4/report.txt` with columns `NAMESPACE POD NODE IMAGES RESTARTS`, sorted by **restart count of the first container** (ascending). Then write the names of pods (format `ns/name`) whose **QoS class is BestEffort** into `/opt/course/4/besteffort.txt`.

<details><summary>Solution</summary>

```bash
k get pod -A --sort-by='.status.containerStatuses[0].restartCount' \
  -o custom-columns='NAMESPACE:.metadata.namespace,POD:.metadata.name,NODE:.spec.nodeName,IMAGES:.spec.containers[*].image,RESTARTS:.status.containerStatuses[0].restartCount' \
  > /opt/course/4/report.txt
k get pod -A -o jsonpath='{range .items[?(@.status.qosClass=="BestEffort")]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' > /opt/course/4/besteffort.txt
```
</details>

---

## Q5 — Timestamps & field selectors (4%)

1. Write the names of the 3 **oldest** pods in namespace `kube-system`, one per line → `/opt/course/5/oldest.txt`.
2. Write all pods in all namespaces that are **not** `Running` (use a field selector) → `/opt/course/5/not-running.txt`.
3. Write a command into `/opt/course/5/sa-tokens.sh` that prints every ServiceAccount in namespace `kube-system` together with its `automountServiceAccountToken` value (empty if unset).

<details><summary>Solution</summary>

```bash
k -n kube-system get pod --sort-by=.metadata.creationTimestamp --no-headers -o custom-columns=:.metadata.name | head -3 > /opt/course/5/oldest.txt
k get pod -A --field-selector=status.phase!=Running > /opt/course/5/not-running.txt
echo "kubectl -n kube-system get sa -o custom-columns=NAME:.metadata.name,AUTOMOUNT:.automountServiceAccountToken" > /opt/course/5/sa-tokens.sh
```

In `custom-columns` a missing field shows `<none>`; jsonpath returns an empty string.
</details>
