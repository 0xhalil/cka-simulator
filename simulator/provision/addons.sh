#!/usr/bin/env bash
# Cluster add-ons that the real exam environment typically has pre-installed.
# Usage: addons.sh <cp-hostname>
set -euo pipefail
CP=$1
export KUBECONFIG=/etc/kubernetes/admin.conf
LOCAL_PATH_VERSION=${LOCAL_PATH_VERSION:-v0.0.37}
GATEWAY_API_VERSION=${GATEWAY_API_VERSION:-v1.6.2}
NGF_VERSION=${NGF_VERSION:-2.7.2}

echo "waiting for nodes to be Ready"
kubectl wait --for=condition=Ready node --all --timeout=600s

# local-path provisioner as the default StorageClass
kubectl apply -f "https://raw.githubusercontent.com/rancher/local-path-provisioner/${LOCAL_PATH_VERSION}/deploy/local-path-storage.yaml"
kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# metrics-server (kubelets use self-signed serving certs in this lab)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deploy metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' || true

if [ "$CP" = cka-cp1 ]; then
  # Gateway API CRDs + NGINX Gateway Fabric as controller (GatewayClass "nginx")
  kubectl apply --server-side -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"
  helm upgrade --install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --version "$NGF_VERSION" \
    --create-namespace -n nginx-gateway \
    --set nginx.service.type=NodePort \
    --set nginxGateway.gwAPIExperimentalFeatures.enable=false --wait --timeout 10m
fi

kubectl -n kube-system rollout status deploy/metrics-server --timeout=300s
kubectl -n kube-system rollout status deploy/coredns --timeout=300s
echo "addons ready on $CP"
