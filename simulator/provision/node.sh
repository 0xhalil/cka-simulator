#!/usr/bin/env bash
# Prepares any cluster node (control plane or worker) the same way a CKA exam node looks:
# Ubuntu + containerd (apt) + kubeadm/kubelet/kubectl from pkgs.k8s.io, crictl, etcdctl, helm.
# Usage: node.sh <hostname> <k8s-minor e.g. 1.37> <node-ip> <role: cp|worker>
set -euo pipefail
NAME=$1; MINOR=$2; NODE_IP=$3; ROLE=$4
export DEBIAN_FRONTEND=noninteractive
cloud-init status --wait >/dev/null 2>&1 || true
systemctl disable --now unattended-upgrades apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 || true
echo 'DPkg::Lock::Timeout "600";' > /etc/apt/apt.conf.d/99lock-timeout

echo "preserve_hostname: true" > /etc/cloud/cloud.cfg.d/99-cka.cfg
hostnamectl set-hostname "$NAME"
grep -q "127.0.1.1 $NAME" /etc/hosts || echo "127.0.1.1 $NAME" >> /etc/hosts

# --- kernel prerequisites -------------------------------------------------------------
cat > /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay; modprobe br_netfilter
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null
swapoff -a || true

# --- packages ------------------------------------------------------------------------------
apt-get update -qq
apt-get install -y -qq apt-transport-https ca-certificates curl gpg jq vim tmux bash-completion \
  tree netcat-openbsd dnsutils iputils-ping containerd >/dev/null

mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${MINOR}/deb/Release.key" | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${MINOR}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update -qq
apt-get install -y -qq kubelet kubeadm kubectl cri-tools >/dev/null
apt-mark hold kubelet kubeadm kubectl >/dev/null

# --- containerd ----------------------------------------------------------------------------
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
PAUSE=$(kubeadm config images list 2>/dev/null | grep pause | head -1)
sed -i -E "s#^(\s*)sandbox_image = .*#\1sandbox_image = \"${PAUSE}\"#; s#^(\s*)sandbox = .*#\1sandbox = \"${PAUSE}\"#" /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >/dev/null
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF

# kubelet must use the user-v2 address (eth0 is the same NAT address on every Lima VM)
echo "KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}" > /etc/default/kubelet
systemctl enable kubelet >/dev/null

# --- tools on control plane nodes ----------------------------------------------------------
if [ "$ROLE" = cp ]; then
  ETCD_TAG=$(kubeadm config images list 2>/dev/null | grep etcd | sed 's/.*://; s/-.*//')
  ARCH=$(dpkg --print-architecture)
  if ! command -v etcdctl >/dev/null; then
    curl -fsSL "https://github.com/etcd-io/etcd/releases/download/v${ETCD_TAG}/etcd-v${ETCD_TAG}-linux-${ARCH}.tar.gz" | tar xz -C /tmp
    install /tmp/etcd-v${ETCD_TAG}-linux-${ARCH}/etcdctl /tmp/etcd-v${ETCD_TAG}-linux-${ARCH}/etcdutl /usr/local/bin/
  fi
  if ! command -v helm >/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash >/dev/null
  fi
fi

# --- exam user ------------------------------------------------------------------------------
id candidate >/dev/null 2>&1 || useradd -m -s /bin/bash candidate
echo "candidate ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/candidate
cat > /home/candidate/.bash_aliases <<'EOF'
alias k=kubectl
source <(kubectl completion bash 2>/dev/null)
complete -o default -F __start_kubectl k
EOF
cat > /home/candidate/.vimrc <<'EOF'
set tabstop=2 shiftwidth=2 expandtab
EOF
chown candidate: /home/candidate/.bash_aliases /home/candidate/.vimrc
echo "node prepared: $NAME ($ROLE, v$MINOR, $NODE_IP)"

# quiet ssh logins (no MOTD), closer to the exam terminal
chmod -x /etc/update-motd.d/* 2>/dev/null || true
