# 12 — Troubleshooting

Scope: application failures, control plane failures, worker node failures, network troubleshooting. The highest-weighted domain in the exam (**30%**). Each question may contain multiple faults — verify end to end before calling it "fixed".

General flow:

```bash
k get pod -A | grep -v Running
k describe pod <p>            # Events!
k logs <p> [-c c] [--previous]
k get events -A --sort-by=.lastTimestamp | tail
ssh <node>; systemctl status kubelet; journalctl -u kubelet -f; crictl ps -a; crictl logs <id>
```

---

## Q1 — Two-tier app is broken (7%)

Namespace `alpha` has a web app (`webapp-mysql` Deployment, Service `web-service` NodePort 30081) that should talk to MySQL (Pod `mysql`, Service `mysql-service`, port 3306). Browsing `http://<node>:30081` shows a DB connection error.

Fix **all** problems (there are three, in different objects). Do not change the DB password.

<details><summary>Solution</summary>

Checklist — each layer one by one:

```bash
k -n alpha get all -o wide
k -n alpha describe svc mysql-service     # Is the selector correct? Endpoints populated? targetPort 3306?
k -n alpha get pod --show-labels
k -n alpha get deploy webapp-mysql -o yaml | grep -A10 env   # DB_Host = mysql-service? DB_User? DB_Password?
k -n alpha get pod mysql -o yaml | grep -A5 env               # MYSQL_ROOT_PASSWORD
k -n alpha describe svc web-service       # nodePort 30081? does the selector match webapp?
```

Typical faults: service selector with wrong label (no endpoints), wrong targetPort, `DB_Host` with wrong service name, wrong `DB_User`, wrong NodePort number. Check endpoints after every fix: `k -n alpha get ep`.
</details>

---

## Q2 — CrashLoopBackOff / ImagePull / Pending triage (5%)

In namespace `triage` there are 4 failing pods: `p1` (`ImagePullBackOff`), `p2` (`CrashLoopBackOff`), `p3` (`Pending`), `p4` (`OOMKilled` repeatedly). Find the root cause for each, write a one-line cause per pod into `/opt/course/2/causes.txt`, and fix them so all are `Running`.

<details><summary>Solution</summary>

```bash
k -n triage describe pod p1 | grep -A5 Events      # image name/tag typo, private registry
k -n triage logs p2 --previous                      # application error / wrong command / missing config
k -n triage describe pod p3 | grep -A5 Events      # Insufficient cpu/memory, untolerated taint, nodeSelector, PVC unbound
k -n triage get pod p4 -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'   # OOMKilled -> increase limit
```

Most pod spec fields are immutable — to fix: `k -n triage get pod p4 -o yaml > p4.yaml; vim p4.yaml; k replace --force -f p4.yaml`. Exit code 137 = SIGKILL (OOM), 1 = application error, 127 = command not found.
</details>

---

## Q3 — kube-apiserver down (8%)

*Host: `ssh controlplane`*

`kubectl` returns `The connection to the server 192.168.x.x:6443 was refused`. Bring the API server back. (Something was changed in its manifest.)

<details><summary>Solution</summary>

```bash
crictl ps -a | grep apiserver                       # Exited, or missing entirely?
crictl logs $(crictl ps -a --name kube-apiserver -q | head -1)
ls /var/log/pods/ | grep apiserver; tail /var/log/pods/kube-system_kube-apiserver-*/kube-apiserver/*.log
journalctl -u kubelet | grep -i apiserver | tail    # YAML parse errors show up here!
vim /etc/kubernetes/manifests/kube-apiserver.yaml
```

Possible faults:
- YAML syntax error → the container is never created; only visible in the kubelet log.
- Wrong flag name (`--etcd-server` vs `--etcd-servers`) → container exits, visible in `crictl logs`.
- Wrong file path (`--client-ca-file=/etc/kubernetes/pki/ca.crtx`).
- `--etcd-servers` wrong port (2380 = peer port).
- Missing volume mount/hostPath.

After fixing, wait 30-60 s; `watch crictl ps`.
</details>

---

## Q4 — Scheduler / controller-manager broken (6%)

*Host: `ssh controlplane`*

New pods stay `Pending` with no events, and scaling Deployment `app` to 3 replicas doesn't create new pods. Fix the cluster.

<details><summary>Solution</summary>

Two separate symptoms = two separate components:
- Pods Pending + no events → **kube-scheduler** is not running.
- Scaling doesn't work (ReplicaSet doesn't create pods) → **kube-controller-manager** is not running.

```bash
k -n kube-system get pod
k -n kube-system describe pod kube-scheduler-controlplane
k -n kube-system logs kube-controller-manager-controlplane
vim /etc/kubernetes/manifests/kube-scheduler.yaml          # command typo (kube-schedulerr), wrong --kubeconfig path
vim /etc/kubernetes/manifests/kube-controller-manager.yaml # wrong volume hostPath (/etc/kubernetes/pki -> /etc/kubernetes/WRONG-PKI-DIRECTORY)
k get deploy app; k get pod -l app=app
```
</details>

---

## Q5 — Worker node NotReady (6%)

`node01` is `NotReady`. Fix it so it becomes `Ready` and stays Ready **after a reboot**.

<details><summary>Solution</summary>

```bash
k describe node node01 | grep -A10 Conditions     # "Kubelet stopped posting node status"
ssh node01
systemctl status kubelet          # inactive (dead)? -> start + enable
systemctl enable --now kubelet
journalctl -u kubelet -n 50 --no-pager
```

Possible layers (check in order):
1. kubelet stopped / disabled → `systemctl enable --now kubelet` (without enable it goes down again after a reboot!).
2. Wrong CA path in the kubelet config (`/var/lib/kubelet/config.yaml` → `clientCAFile`).
3. Wrong apiserver port in `/etc/kubernetes/kubelet.conf` (6553 vs 6443).
4. containerd stopped → `systemctl status containerd`.
5. CNI missing/broken → node Ready but pods `ContainerCreating` (`NetworkPluginNotReady`).
</details>

---

## Q6 — Service unreachable: kube-proxy (6%)

Pods can reach each other by IP but **no Service ClusterIP works** anywhere in the cluster. DNS also fails (because it goes through the `kube-dns` Service). Fix it.

<details><summary>Solution</summary>

```bash
k -n kube-system get ds kube-proxy; k -n kube-system get pod -l k8s-app=kube-proxy
k -n kube-system logs -l k8s-app=kube-proxy
k -n kube-system get cm kube-proxy -o yaml | grep -E 'kubeconfig|clusterCIDR|mode'
k -n kube-system get ds kube-proxy -o yaml | grep -A5 command    # --config=/var/lib/kube-proxy/config.conf ?
```

Typical: the `--config` path in the DaemonSet doesn't match the file name the ConfigMap is mounted as (`configuration.conf` vs `config.conf`), or the `kubeconfig` path in the ConfigMap is wrong. Fix → `k -n kube-system rollout restart ds kube-proxy`. Verify: `k run t --rm -it --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default`.
</details>

---

## Q7 — CNI broken: pods stuck in ContainerCreating (5%)

After a maintenance window, new pods on all nodes stay in `ContainerCreating` with an event like `failed to setup network for sandbox ... plugin type="..." failed`. Existing pods still work. Fix it.

<details><summary>Solution</summary>

```bash
k describe pod <new-pod> | tail
k -n kube-system get pod | grep -Ei 'calico|flannel|weave|cilium'   # is the CNI DaemonSet running?
ssh node01 'ls -l /etc/cni/net.d/ /opt/cni/bin/'
```

Possibilities: CNI DaemonSet deleted/scaled down (its nodeSelector matches no nodes), `/etc/cni/net.d` config corrupted, plugin binary missing, the CNI's own pod CIDR conflicts with `--cluster-cidr`. Fix/re-apply the DaemonSet and recreate the new pods.
</details>

---

## Q8 — NetworkPolicy blocks traffic (4%)

In namespace `secure`, pod `client` can no longer reach Service `api-svc:80`. Nobody changed the pods or services. Find out why and fix it **without deleting any NetworkPolicy**: add the minimum new policy (or edit one) so only `client` → `api` on port 80 is allowed.

<details><summary>Solution</summary>

```bash
k -n secure get netpol
k -n secure describe netpol                                   # is there a default-deny? is egress blocked too?
k -n secure get pod --show-labels
k -n secure get svc api-svc -o yaml | grep -A3 ports          # targetPort -> this port goes in the policy (not the service port!)
```

Think in both directions: ingress allow for `api` **and** egress allow for `client` (+ DNS egress, if the client uses the service name). The NetworkPolicy port is the **pod/targetPort**, not the Service port.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: allow-client-api, namespace: secure}
spec:
  podSelector: {matchLabels: {app: api}}
  policyTypes: [Ingress]
  ingress:
  - from: [{podSelector: {matchLabels: {app: client}}}]
    ports: [{port: 8080, protocol: TCP}]    # targetPort
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: client-egress, namespace: secure}
spec:
  podSelector: {matchLabels: {app: client}}
  policyTypes: [Egress]
  egress:
  - to: [{podSelector: {matchLabels: {app: api}}}]
    ports: [{port: 8080, protocol: TCP}]
  - ports: [{port: 53, protocol: UDP}, {port: 53, protocol: TCP}]
```
</details>
