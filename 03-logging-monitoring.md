# 03 — Logging & Monitoring

Scope: metrics-server, `kubectl top`, container logs, multi-container logs, previous container logs, kubelet/control-plane logs.

---

## Q1 — Install & use metrics-server (5%)

`kubectl top nodes` currently fails with `Metrics API not available`.

1. Install metrics-server from the official manifest. The kubelets use self-signed serving certificates, so make it work in this lab (`--kubelet-insecure-tls`).
2. Write a script `/opt/course/1/top-nodes.sh` that shows node resource usage, and `/opt/course/1/top-pods.sh` that shows usage of **all pods in all namespaces including their containers**, sorted by memory.

<details><summary>Solution</summary>

```bash
k apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
k -n kube-system edit deploy metrics-server
#   under args:  - --kubelet-insecure-tls
k -n kube-system rollout status deploy metrics-server
k top nodes
echo 'kubectl top node' > /opt/course/1/top-nodes.sh
echo 'kubectl top pod -A --containers --sort-by=memory' > /opt/course/1/top-pods.sh
```

Note: `--sort-by` only accepts `cpu` or `memory`.
</details>

---

## Q2 — Find the hungriest pod (3%)

Across **all namespaces**, find the pod that currently consumes the most CPU, and the node with the highest memory usage percentage. Write them as:

```
pod: <namespace>/<name>
node: <name>
```

into `/opt/course/2/top.txt`.

<details><summary>Solution</summary>

```bash
k top pod -A --sort-by=cpu --no-headers | head -1        # NAMESPACE NAME CPU MEM
k top node --sort-by=memory --no-headers | head -1        # look at the MEMORY% column
```

Note: `top node --sort-by=memory` sorts by absolute value, not percentage — if node capacities differ, compare the `MEMORY%` column manually.
</details>

---

## Q3 — Multi-container logs (4%)

Pod `app-log` in namespace `logging` has two containers: `app` and `sidecar`.

1. Save the last **50** lines of the `sidecar` container's logs, **with timestamps**, to `/opt/course/3/sidecar.log`.
2. Save all log lines of the `app` container from the last **10 minutes** that contain `ERROR` to `/opt/course/3/errors.log`.
3. The `app` container restarted once. Save the logs of its **previous** instance to `/opt/course/3/previous.log`.

<details><summary>Solution</summary>

```bash
k -n logging logs app-log -c sidecar --tail=50 --timestamps > /opt/course/3/sidecar.log
k -n logging logs app-log -c app --since=10m | grep ERROR > /opt/course/3/errors.log
k -n logging logs app-log -c app --previous > /opt/course/3/previous.log
```

Without `-c`, a multi-container pod uses the `kubectl.kubernetes.io/default-container` annotation or the first container — always pass `-c` in the exam.
</details>

---

## Q4 — Logs when kubectl doesn't help (5%)

*Host: `ssh node01`*

A pod `ghost` was scheduled on node01 and keeps failing; the API currently shows no useful logs.

1. Using the container runtime CLI on `node01`, find the container ID(s) belonging to pod `ghost` and write the **runtime** logs of the most recent one into `/opt/course/4/ghost.log`.
2. Write the last 30 lines of the **kubelet** log on node01 into `/opt/course/4/kubelet.log`.
3. Write the path of the directory where node01 stores pod log files on disk into `/opt/course/4/path.txt`.

<details><summary>Solution</summary>

```bash
ssh node01
crictl pods --name ghost
crictl ps -a --pod <POD_ID>
crictl logs <CONTAINER_ID> > /opt/course/4/ghost.log 2>&1   # include stderr too!
journalctl -u kubelet --no-pager | tail -30 > /opt/course/4/kubelet.log
echo /var/log/pods > /opt/course/4/path.txt     # (/var/log/containers -> symlinks)
```

`crictl logs` outputs both stdout and stderr; without `2>&1`, stderr doesn't end up in the file.
</details>

---

## Q5 — Sort and filter events (3%)

Write a command into `/opt/course/5/events.sh` that shows **all events in all namespaces sorted by creation/last timestamp**, and a second command into `/opt/course/5/warnings.sh` that shows only `Warning` events in namespace `kube-system`.

Then delete the `kube-proxy` pod on `node01` and save the resulting events (from the event command) into `/opt/course/5/proxy-events.log`.

<details><summary>Solution</summary>

```bash
echo 'kubectl get events -A --sort-by=.metadata.creationTimestamp' > /opt/course/5/events.sh
echo 'kubectl -n kube-system get events --field-selector type=Warning' > /opt/course/5/warnings.sh
k -n kube-system get pod -o wide -l k8s-app=kube-proxy | grep node01
k -n kube-system delete pod kube-proxy-xxxxx
bash /opt/course/5/events.sh | grep kube-proxy > /opt/course/5/proxy-events.log
```
</details>
