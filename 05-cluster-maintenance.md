# 05 — Cluster Maintenance

Scope: OS upgrade (cordon/drain/uncordon), Kubernetes versions, cluster upgrade with kubeadm, etcd backup & restore (`etcdctl`, `etcdutl`).

---

## Q1 — Drain a node safely (4%)

`node01` must go down for kernel patching.

1. Evict all workloads from `node01`. There is a DaemonSet and a pod `lonely` (not managed by any controller) using an `emptyDir`. Drain must succeed.
2. Write which pod(s) were **permanently lost** into `/opt/course/1/lost.txt`.
3. After maintenance, make node01 schedulable again. Do pods move back automatically? Answer `yes`/`no` into `/opt/course/1/moveback.txt`.

<details><summary>Solution</summary>

```bash
k get pod -A -o wide --field-selector spec.nodeName=node01
k drain node01 --ignore-daemonsets --delete-emptydir-data --force
echo default/lonely > /opt/course/1/lost.txt     # pod without a controller -> doesn't come back
k uncordon node01
echo no > /opt/course/1/moveback.txt
```

- `--force`: required for pods not owned by a controller.
- `--delete-emptydir-data`: confirms that emptyDir data will be deleted.
- If there is a PodDisruptionBudget, drain waits/fails — check `k get pdb -A`.
- `cordon` only blocks new scheduling; existing pods stay.
</details>

---

## Q2 — Upgrade the control plane (10%)

*Host: `ssh controlplane`*

The cluster runs Kubernetes `v1.33.x`. Upgrade the **controlplane** node to the latest patch of `v1.34` (kubeadm, kubelet, kubectl). Workloads must be drained from controlplane during the upgrade and controlplane must be schedulable again afterwards (as it was before).

<details><summary>Solution</summary>

```bash
ssh controlplane
cat /etc/apt/sources.list.d/kubernetes.list
# change v1.33 -> v1.34:
sed -i 's#/v1.33/#/v1.34/#' /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-cache madison kubeadm | head          # e.g. 1.34.1-1.1

apt-mark unhold kubeadm && apt-get install -y kubeadm='1.34.1-1.1' && apt-mark hold kubeadm
kubeadm version
kubeadm upgrade plan
kubeadm upgrade apply v1.34.1

kubectl drain controlplane --ignore-daemonsets
apt-mark unhold kubelet kubectl && apt-get install -y kubelet='1.34.1-1.1' kubectl='1.34.1-1.1' && apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
kubectl uncordon controlplane
kubectl get nodes
```

Order: kubeadm → `upgrade apply` → drain → kubelet/kubectl → restart → uncordon.
Minor versions can't be skipped (1.32 → 1.34 directly is not possible). On other control-plane nodes use `kubeadm upgrade node` instead of `upgrade apply`.
</details>

---

## Q3 — Upgrade a worker node (6%)

*Host: `ssh node01`*

After Q2, upgrade `node01` to the same version as the control plane.

<details><summary>Solution</summary>

```bash
# from controlplane:
k drain node01 --ignore-daemonsets
ssh node01
sed -i 's#/v1.33/#/v1.34/#' /etc/apt/sources.list.d/kubernetes.list && apt-get update
apt-mark unhold kubeadm && apt-get install -y kubeadm='1.34.1-1.1' && apt-mark hold kubeadm
kubeadm upgrade node
apt-mark unhold kubelet kubectl && apt-get install -y kubelet='1.34.1-1.1' kubectl='1.34.1-1.1' && apt-mark hold kubelet kubectl
systemctl daemon-reload && systemctl restart kubelet
exit
k uncordon node01
k get nodes        # VERSION column shows the kubelet version
```

Version skew: the kubelet can be up to **3 minor** versions older than kube-apiserver, **never newer**.
</details>

---

## Q4 — etcd snapshot (5%)

*Host: `ssh controlplane`*

Create a snapshot of the running etcd at `/opt/course/4/etcd-snapshot.db`. Then write the snapshot's **status** (hash, revision, total keys, size) in **table** format into `/opt/course/4/status.txt`.

<details><summary>Solution</summary>

```bash
grep -E 'listen-client|cert-file|key-file|trusted-ca' /etc/kubernetes/manifests/etcd.yaml
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/course/4/etcd-snapshot.db

etcdutl snapshot status /opt/course/4/etcd-snapshot.db -w table > /opt/course/4/status.txt
```

`etcdctl snapshot status/restore` was deprecated in v3.5 and removed in v3.6 → use **`etcdutl`**. `save` is still done with `etcdctl` (it connects to the live server).
</details>

---

## Q5 — etcd restore (10%)

*Host: `ssh controlplane`*

After taking the snapshot in Q4, someone created namespace `oops` and deleted Deployment `important` in namespace `default`.

Restore the cluster state from `/opt/course/4/etcd-snapshot.db`. Use a **new data directory** `/var/lib/etcd-restored`. After the restore, `important` must exist again and `oops` must be gone.

<details><summary>Solution</summary>

```bash
etcdutl snapshot restore /opt/course/4/etcd-snapshot.db --data-dir /var/lib/etcd-restored

vim /etc/kubernetes/manifests/etcd.yaml
#  volumes:
#  - hostPath:
#      path: /var/lib/etcd-restored     # <- change only the hostPath
#      type: DirectoryOrCreate
#    name: etcd-data
# (--data-dir=/var/lib/etcd and mountPath can stay the same; path inside the container)

watch crictl ps            # etcd and kube-apiserver should restart (1-2 min)
# if stuck: restart the kubelet, or move the apiserver manifest out and back in
k get ns oops              # NotFound
k get deploy important
```

Common mistake: changing `--data-dir` inside the container without changing the volume mount → etcd starts with an empty directory = empty cluster.
</details>

---

## Q6 — Kubernetes versions & components (3%)

Write the following into `/opt/course/6/versions.txt`:

```
apiserver: <version>
kubelet-node01: <version>
etcd: <version>
coredns: <version>
```

<details><summary>Solution</summary>

```bash
k version                                                          # Server Version
k get node node01 -o jsonpath='{.status.nodeInfo.kubeletVersion}'
k -n kube-system get pod etcd-controlplane -o jsonpath='{.spec.containers[0].image}'
k -n kube-system get deploy coredns -o jsonpath='{.spec.template.spec.containers[0].image}'
# alternative: kubeadm upgrade plan (lists the components)
```
</details>
