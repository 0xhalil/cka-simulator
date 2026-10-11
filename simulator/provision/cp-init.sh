#!/usr/bin/env bash
# kubeadm init + Calico (VXLAN, NetworkPolicy capable) on a control plane node.
# Usage: cp-init.sh <node-ip> <k8s-version e.g. v1.37.1> <pod-cidr> <svc-cidr>
set -euo pipefail
NODE_IP=$1; VERSION=$2; POD_CIDR=$3; SVC_CIDR=$4
CALICO_VERSION=${CALICO_VERSION:-v3.32.2}
export KUBECONFIG=/etc/kubernetes/admin.conf

if [ ! -f /etc/kubernetes/admin.conf ]; then
  cat > /root/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${NODE_IP}
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
  kubeletExtraArgs:
  - name: node-ip
    value: ${NODE_IP}
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: ${VERSION}
networking:
  podSubnet: ${POD_CIDR}
  serviceSubnet: ${SVC_CIDR}
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF
  kubeadm init --config /root/kubeadm-config.yaml --upload-certs
fi

# Calico from the plain manifest, switched from IPIP/BGP to VXLAN (works over Lima user-v2 network)
if ! kubectl -n kube-system get ds calico-node >/dev/null 2>&1; then
  curl -fsSL "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/calico.yaml" -o /root/calico.yaml
  python3 - "$POD_CIDR" <<'PY'
import sys, re
cidr = sys.argv[1]
p = '/root/calico.yaml'; s = open(p).read()
s = s.replace('calico_backend: "bird"', 'calico_backend: "vxlan"')
s = re.sub(r'(- name: CALICO_IPV4POOL_IPIP\n\s*value: )"Always"', r'\1"Never"', s)
s = re.sub(r'(- name: CALICO_IPV4POOL_VXLAN\n\s*value: )"Never"', r'\1"Always"', s)
s = re.sub(r'# (- name: CALICO_IPV4POOL_CIDR)\n(\s*)#   value: "192.168.0.0/16"',
           r'\1\n\2  value: "%s"' % cidr, s)
s = s.replace('- name: IP\n              value: "autodetect"',
              '- name: IP\n              value: "autodetect"\n            - name: IP_AUTODETECTION_METHOD\n              value: "kubernetes-internal-ip"')
s = re.sub(r'\n\s*- -bird-live', '', s)
s = re.sub(r'\n\s*- -bird-ready', '', s)
open(p, 'w').write(s)
PY
  kubectl apply -f /root/calico.yaml >/dev/null
fi

# kubeconfig for root and the exam user
mkdir -p /root/.kube /home/candidate/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
cp /etc/kubernetes/admin.conf /home/candidate/.kube/config
chown -R candidate: /home/candidate/.kube

kubeadm token create --print-join-command > /root/join.sh
echo "control plane ready"
