# 09 — Design & Install a Kubernetes Cluster (kubeadm)

Scope: cluster design, HA control plane, etcd HA (stacked vs external), container runtime (containerd) preparation, kubeadm init/join, CNI installation.

> Note: In the current CKA curriculum, "installing a cluster/adding nodes with kubeadm" and "container runtime / CNI installation" can be asked directly. This unit carries a high weight in the exam (~25% Cluster Architecture, Installation & Configuration).

---

## Q1 — Prepare a node for Kubernetes (6%)

*Host: `ssh node03`* (fresh Ubuntu, containerd binary installed but not configured)

Prepare the node so it can join a kubeadm cluster:

1. Load kernel modules `overlay` and `br_netfilter` persistently.
2. Set sysctls `net.bridge.bridge-nf-call-iptables=1`, `net.bridge.bridge-nf-call-ip6tables=1`, `net.ipv4.ip_forward=1` persistently.
3. Configure containerd to use the **systemd cgroup driver** and restart it.
4. Disable swap (or confirm it's off).
5. Install `kubeadm`, `kubelet`, `kubectl` matching the control plane's version and hold them.

<details><summary>Solution</summary>

```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay; sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

sudo swapoff -a; sudo sed -i '/ swap / s/^/#/' /etc/fstab

# pkgs.k8s.io repo (same minor as controlplane)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl
```

In containerd 2.x the config structure is different; find the `SystemdCgroup` line with `grep -n SystemdCgroup`. kubeadm v1.22+ configures the kubelet with the `systemd` cgroup driver by default — if it doesn't match the runtime, pods keep restarting.
</details>

---

## Q2 — kubeadm init (8%)

*Host: `ssh cp-new`* (prepared node)

Initialize a new cluster with:

- Pod network CIDR `10.244.0.0/16`, service CIDR `10.96.0.0/16`
- API server advertise address = node's InternalIP
- Additional apiserver cert SAN `k8s.lab.local`

Then make `kubectl` work for the current user and install a CNI (Flannel or Calico — use the manifest URL provided at `/opt/course/2/cni-url.txt`). The node must become `Ready`.

<details><summary>Solution</summary>

```bash
IP=$(ip -4 -br addr show eth0 | awk '{print $3}' | cut -d/ -f1)
sudo kubeadm init \
  --apiserver-advertise-address=$IP \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/16 \
  --apiserver-cert-extra-sans=k8s.lab.local

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f $(cat /opt/course/2/cni-url.txt)
kubectl get nodes -w
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -ext subjectAltName | grep k8s.lab.local
```

Until a CNI is installed, the node stays `NotReady` and CoreDNS `Pending` — this is normal. Flannel expects `10.244.0.0/16` by default; if you used a different CIDR, edit `net-conf.json` in the manifest.
</details>

---

## Q3 — Join a worker with an expired token (5%)

`node03` (prepared in Q1) must join the existing cluster. The original join token has expired.

1. Generate a new join command on the control plane.
2. Join `node03` and verify it's `Ready`.
3. Write the **CA cert hash** used in the join command to `/opt/course/3/hash.txt`.

<details><summary>Solution</summary>

```bash
ssh controlplane
kubeadm token list
kubeadm token create --print-join-command
# kubeadm join 192.168.1.10:6443 --token abc.xyz --discovery-token-ca-cert-hash sha256:....
ssh node03 'sudo kubeadm join ...'
k get nodes

# computing the hash manually:
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | sha256sum | awk '{print "sha256:"$1}' > /opt/course/3/hash.txt
```
</details>

---

## Q4 — HA design questions (3%)

Answer in `/opt/course/4/answers.txt`:

1. Minimum number of etcd members to tolerate **2** member failures?
2. In a **stacked** etcd topology with 3 control-plane nodes, how many nodes can fail before the cluster loses quorum?
3. In an HA cluster, which control-plane components run **active/active** and which run **active/standby** (leader election)?
4. What must sit in front of multiple kube-apiservers, and what kubeadm init flag points at it?

<details><summary>Solution</summary>

```
1. 5   (quorum = floor(n/2)+1 ; 5 -> quorum 3 -> 2 failure tolerated)
2. 1
3. active/active: kube-apiserver (and etcd members all serve); active/standby: kube-controller-manager, kube-scheduler
4. A load balancer (e.g. HAProxy/keepalived); kubeadm init --control-plane-endpoint=<LB:6443> (+ --upload-certs for joining CPs)
```

An even number of etcd members doesn't increase fault tolerance (4 members → still tolerates 1 failure).
</details>

---

## Q5 — Broken kubelet after install (5%)

*Host: `ssh node03`*

After a junior admin edited files, `node03` shows `NotReady`. `systemctl status kubelet` shows it is crash-looping. Fix it. (Hint: look at both the systemd drop-in and the kubelet config file.)

<details><summary>Solution</summary>

```bash
systemctl status kubelet
journalctl -u kubelet -n 50 --no-pager
cat /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf   # ExecStart, --config, --kubeconfig
cat /var/lib/kubelet/config.yaml       # clientCAFile, cgroupDriver, staticPodPath
cat /var/lib/kubelet/kubeadm-flags.env
cat /etc/kubernetes/kubelet.conf        # is the server: address/port correct?
which kubelet                           # does the binary path match ExecStart?
# Typical errors: wrong binary path (/usr/local/bin vs /usr/bin), wrong clientCAFile path,
# wrong apiserver port in kubelet.conf, cgroupDriver mismatch
systemctl daemon-reload && systemctl restart kubelet
```
</details>
