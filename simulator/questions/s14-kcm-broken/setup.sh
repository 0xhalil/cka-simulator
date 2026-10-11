# >>> c2-helpers (generated from dev/reset-cluster2.sh - edit there, then run dev/sync-c2-helpers.sh)
C2B=/root/cka-baseline
C2M=/etc/kubernetes/manifests
C2API=$(awk '/server:/{print $2; exit}' /etc/kubernetes/admin.conf)
c2_api_ok() { kubectl get --raw=/readyz >/dev/null 2>&1; }
c2_wait_api() { local i; for i in $(seq 1 $(( ${1:-180} / 3 ))); do c2_api_ok && return 0; sleep 3; done; echo "WARN apiserver not ready"; return 1; }
c2_cid() { crictl ps --name "^$1\$" -s Running -q 2>/dev/null | head -1; }
c2_health() {
  case $1 in
    kube-apiserver) c2_api_ok ;;
    etcd) curl -sf http://127.0.0.1:2381/readyz >/dev/null ;;
    kube-controller-manager) curl -skf https://127.0.0.1:10257/healthz >/dev/null ;;
    kube-scheduler) curl -skf https://127.0.0.1:10259/healthz >/dev/null ;;
  esac
}
c2_wait_comp() { local i; for i in $(seq 1 ${2:-60}); do [ -n "$(c2_cid $1)" ] && c2_health $1 && return 0; sleep 3; done; echo "WARN $1 not healthy"; return 1; }
# c2_put_manifest <component> <file>: install manifest if it differs, wait for the new container + health
c2_put_manifest() {
  local n=$1 src=$2 old c i
  if cmp -s "$src" "$C2M/$n.yaml"; then c2_wait_comp $n; return; fi
  old=$(c2_cid $n)
  cp "$src" "$C2M/$n.yaml"
  for i in $(seq 1 60); do c=$(c2_cid $n); [ -n "$c" ] && [ "$c" != "$old" ] && break; sleep 2; done
  c2_wait_comp $n 80
}
c2_clean_json() {
  jq 'del(.status, .metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.generation,
          .metadata.managedFields, .metadata.annotations["deprecated.daemonset.template.generation"],
          .metadata.annotations["deployment.kubernetes.io/revision"],
          .metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"])'
}
# capture pristine copies once (run while the cluster is healthy)
c2_init() {
  local n src
  mkdir -p $C2B/manifests $C2B/stray
  for n in etcd kube-apiserver kube-controller-manager kube-scheduler; do
    [ -s $C2B/manifests/$n.yaml ] && continue
    src=$C2M/$n.yaml
    [ $n = kube-scheduler ] && [ -s /root/kube-scheduler.yaml.orig ] && src=/root/kube-scheduler.yaml.orig
    cp "$src" $C2B/manifests/$n.yaml
  done
  if [ ! -s $C2B/coredns-svc.json ] && c2_api_ok; then
    kubectl -n kube-system get cm kube-proxy -o json | c2_clean_json > $C2B/kube-proxy-cm.json
    kubectl -n kube-system get ds kube-proxy -o json | c2_clean_json > $C2B/kube-proxy-ds.json
    kubectl -n kube-system get cm coredns -o json | c2_clean_json > $C2B/coredns-cm.json
    kubectl -n kube-system get deploy coredns -o json | c2_clean_json > $C2B/coredns-deploy.json
    kubectl -n kube-system get svc kube-dns -o json | c2_clean_json > $C2B/coredns-svc.json
  fi
  on cka-w2 'mkdir -p /root/cka-baseline; [ -s /root/cka-baseline/10-kubeadm.conf ] || cp /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf /root/cka-baseline/' 2>/dev/null
}
# move everything that is not one of the 4 kubeadm manifests out of the manifests dir
c2_clean_manifests() {
  local f
  for f in $C2M/*; do
    case ${f##*/} in etcd.yaml|kube-apiserver.yaml|kube-controller-manager.yaml|kube-scheduler.yaml) ;;
      *) [ -e "$f" ] && mv "$f" $C2B/stray/"${f##*/}.$(date +%s)" ;; esac
  done
}
# if the apiserver uses an EncryptionConfiguration: switch to identity-first, rewrite data, so the flag can be dropped safely
c2_undo_encryption() {
  local m=$C2M/kube-apiserver.yaml f old i c res
  grep -q -- '--encryption-provider-config=' $m || return 0
  echo "undoing encryption at rest"
  f=$(python3 - "$m" <<'PY'
import sys, yaml
pod = yaml.safe_load(open(sys.argv[1]))
ctr = pod["spec"]["containers"][0]
arg = [a for a in ctr["command"] if a.startswith("--encryption-provider-config=")][0].split("=", 1)[1]
vols = {v["name"]: v.get("hostPath", {}).get("path") for v in pod["spec"].get("volumes", [])}
best = None
for vm in ctr.get("volumeMounts", []):
    mp = vm["mountPath"].rstrip("/")
    if (arg == mp or arg.startswith(mp + "/")) and vols.get(vm["name"]) and (best is None or len(mp) > len(best[0])):
        best = (mp, vols[vm["name"]])
print(best[1] + arg[len(best[0]):] if best else arg)
PY
)
  if [ -f "$f" ] && c2_api_ok; then
    res=$(python3 - "$f" <<'PY'
import sys, yaml
p = sys.argv[1]; cfg = yaml.safe_load(open(p)); out = set()
for r in cfg.get("resources", []):
    r["providers"] = [{"identity": {}}] + [x for x in r.get("providers", []) if "identity" not in x]
    for n in r.get("resources", []):
        out.add("secrets" if n in ("*.*", "*.", "secrets") else n)
yaml.safe_dump(cfg, open(p, "w"))
print(" ".join(sorted(out)))
PY
)
    old=$(c2_cid kube-apiserver); crictl stop "$old" >/dev/null 2>&1
    for i in $(seq 1 60); do c=$(c2_cid kube-apiserver); [ -n "$c" ] && [ "$c" != "$old" ] && break; sleep 2; done
    c2_wait_api 180
    for r in $res; do kubectl get "$r" -A -o json 2>/dev/null | kubectl replace -f - >/dev/null 2>&1; done
  fi
}
c2_restore_etcd() {
  c2_put_manifest etcd $C2B/manifests/etcd.yaml
  rm -rf /var/lib/etcd-restore /var/lib/etcd-backup-restore
  c2_wait_api 180
}
c2_restore_apiserver() {
  c2_undo_encryption
  c2_put_manifest kube-apiserver $C2B/manifests/kube-apiserver.yaml
  rm -rf /etc/kubernetes/enc
  c2_wait_api 180
}
c2_restore_kcm() { c2_put_manifest kube-controller-manager $C2B/manifests/kube-controller-manager.yaml; rmdir /etc/kubernetes/certs 2>/dev/null; true; }
c2_restore_scheduler() { c2_put_manifest kube-scheduler $C2B/manifests/kube-scheduler.yaml; }
c2_restore_certs() {
  openssl x509 -checkend $((30*86400)) -noout -in /etc/kubernetes/pki/apiserver.crt >/dev/null 2>&1 && return 0
  echo "renewing apiserver cert"
  kubeadm certs renew apiserver >/dev/null 2>&1
  local old=$(c2_cid kube-apiserver); crictl stop "$old" >/dev/null 2>&1; sleep 5; c2_wait_api 180
}
c2_restore_kubeproxy() {
  c2_wait_api 120
  if [ "$(kubectl -n kube-system get cm kube-proxy -o json | jq -S .data)" != "$(jq -S .data $C2B/kube-proxy-cm.json)" ]; then
    kubectl replace -f $C2B/kube-proxy-cm.json >/dev/null; kubectl -n kube-system delete pod -l k8s-app=kube-proxy --wait=false >/dev/null
  fi
  if [ "$(kubectl -n kube-system get ds kube-proxy -o json | jq -S .spec)" != "$(jq -S .spec $C2B/kube-proxy-ds.json)" ]; then
    kubectl replace -f $C2B/kube-proxy-ds.json >/dev/null
  fi
  kubectl -n kube-system rollout status ds kube-proxy --timeout=180s >/dev/null || echo "WARN kube-proxy rollout"
}
c2_restore_coredns() {
  c2_wait_api 120
  local rs=0
  if [ "$(kubectl -n kube-system get cm coredns -o json | jq -S .data)" != "$(jq -S .data $C2B/coredns-cm.json)" ]; then
    kubectl replace -f $C2B/coredns-cm.json >/dev/null; rs=1
  fi
  if [ "$(kubectl -n kube-system get svc kube-dns -o json | jq -S '.spec.selector,.spec.ports')" != "$(jq -S '.spec.selector,.spec.ports' $C2B/coredns-svc.json)" ]; then
    kubectl replace -f $C2B/coredns-svc.json >/dev/null
  fi
  if [ "$(kubectl -n kube-system get deploy coredns -o json | jq -S '.spec | del(.template.metadata.annotations)')" != "$(jq -S '.spec | del(.template.metadata.annotations)' $C2B/coredns-deploy.json)" ]; then
    kubectl replace -f $C2B/coredns-deploy.json >/dev/null
  fi
  [ $rs = 1 ] && kubectl -n kube-system rollout restart deploy coredns >/dev/null
  kubectl -n kube-system rollout status deploy coredns --timeout=180s >/dev/null || echo "WARN coredns rollout"
}
# (re)join cka-w2 with the version currently installed there
c2_rejoin_w2() {
  echo "re-joining cka-w2"
  kubectl delete node cka-w2 --ignore-not-found --wait=true --timeout=60s >/dev/null 2>&1
  local join i
  join=$(kubeadm token create --ttl 30m --description "cka-sim internal rejoin" --print-join-command)
  on cka-w2 "kubeadm reset -f >/dev/null 2>&1; rm -rf /etc/cni/net.d/*; sysctl -qw net.ipv4.ip_forward=1; systemctl enable kubelet >/dev/null 2>&1; $join >/dev/null"
  for i in $(seq 1 60); do kubectl get node cka-w2 >/dev/null 2>&1 && break; sleep 3; done
}
c2_restore_w2() {
  c2_wait_api 120
  if ! kubectl get node cka-w2 >/dev/null 2>&1 || ! on cka-w2 'test -s /etc/kubernetes/kubelet.conf && test -s /var/lib/kubelet/config.yaml'; then c2_rejoin_w2; fi
  on cka-w2 "
    ch=0
    sysctl -qw net.ipv4.ip_forward=1
    grep -Eq '^net.ipv4.ip_forward *= *1' /etc/sysctl.d/k8s.conf 2>/dev/null || echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.d/k8s.conf
    if [ -n \"\$(ls -A /etc/systemd/system/kubelet.service.d 2>/dev/null)\" ]; then rm -rf /etc/systemd/system/kubelet.service.d/*; ch=1; fi
    if [ -s /root/cka-baseline/10-kubeadm.conf ] && ! cmp -s /root/cka-baseline/10-kubeadm.conf /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf; then
      cp /root/cka-baseline/10-kubeadm.conf /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf; ch=1; fi
    grep -q 'server: $C2API\$' /etc/kubernetes/kubelet.conf || { sed -i -E 's#server: https://.*#server: $C2API#' /etc/kubernetes/kubelet.conf; ch=1; }
    grep -q 'clientCAFile: /etc/kubernetes/pki/ca.crt\$' /var/lib/kubelet/config.yaml || { sed -i 's#clientCAFile: .*#clientCAFile: /etc/kubernetes/pki/ca.crt#' /var/lib/kubelet/config.yaml; ch=1; }
    systemctl is-enabled -q kubelet || systemctl enable kubelet >/dev/null 2>&1
    systemctl is-active -q kubelet || ch=1
    if [ \$ch = 1 ]; then systemctl daemon-reload; systemctl restart kubelet; fi
  "
  kubectl wait --for=condition=Ready node/cka-w2 --timeout=240s >/dev/null || echo "WARN cka-w2 not Ready"
  kubectl uncordon cka-w2 >/dev/null 2>&1
}
c2_reset_all() {
  c2_init
  c2_clean_manifests
  c2_restore_etcd
  c2_restore_apiserver
  c2_restore_certs
  c2_restore_kcm
  c2_restore_scheduler
  c2_wait_api 180
  kubectl delete validatingadmissionpolicybinding vap-replica-cap-binding --ignore-not-found >/dev/null 2>&1
  kubectl delete validatingadmissionpolicy vap-replica-cap --ignore-not-found >/dev/null 2>&1
  c2_restore_kubeproxy
  c2_restore_coredns
  c2_restore_w2
  kubectl uncordon cka-cp2 >/dev/null 2>&1
  kubectl get nodes
  kubectl -n kube-system get pods
}
# <<< c2-helpers
c2_init
c2_clean_manifests
c2_wait_api 180
c2_restore_kcm
reset_ns kcm-lab
mk() {
cat <<YAML | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: $1, namespace: kcm-lab}
spec:
  replicas: $2
  selector: {matchLabels: {app: $1}}
  template:
    metadata: {labels: {app: $1}}
    spec:
      tolerations: [{key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}]
      containers:
      - name: app
        image: busybox:1.36
        command: ["sleep", "1d"]
        resources: {requests: {cpu: 5m, memory: 8Mi}}
YAML
}
mk beacon 1
wait_deploy kcm-lab beacon 120
# break: the pki hostPath volume of the controller-manager points to an empty directory
sed 's#path: /etc/kubernetes/pki$#path: /etc/kubernetes/certs#' $C2B/manifests/kube-controller-manager.yaml > /root/.kcm.tmp
mv /root/.kcm.tmp $C2M/kube-controller-manager.yaml
for i in $(seq 1 60); do [ -z "$(c2_cid kube-controller-manager)" ] && break; sleep 2; done
sleep 10
mk pulse 2
kubectl -n kcm-lab scale deploy beacon --replicas=3 >/dev/null
