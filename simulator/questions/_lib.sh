#!/usr/bin/env bash
# Prepended to every setup.sh / check.sh. Runs as root on the question's host.
export KUBECONFIG=/etc/kubernetes/admin.conf
export PATH=$PATH:/usr/local/bin
k() { kubectl "$@"; }

# check "<description>" <shell condition...>   -> prints PASS/FAIL line for the grader
check() {
  local desc=$1; shift
  if ( eval "$*" ) >/dev/null 2>&1; then echo "PASS $desc"; else echo "FAIL $desc"; fi
}
# guard "<description>" <condition>  -> a constraint ("don't modify X"); only scores if a real objective passed
guard() { local desc=$1; shift; check "[guard] $desc" "$@"; }
# jp <kubectl get args...> <jsonpath>   -> value or empty
jp() { local path=${*: -1}; set -- "${@:1:$#-1}"; kubectl get "$@" -o jsonpath="$path" 2>/dev/null; }

# run a command on another node as root (setup/check only; candidate uses their own ssh)
on() { local h=$1; shift; ssh -o BatchMode=yes -o ConnectTimeout=10 "root@$h" "$@" </dev/null; }

wait_deploy() { kubectl -n "$1" rollout status "deploy/$2" --timeout="${3:-180s}" >/dev/null 2>&1; }
reset_ns() {  # delete and recreate a namespace (idempotent scenario reset)
  for ns in "$@"; do
    kubectl delete ns "$ns" --ignore-not-found --wait=false >/dev/null 2>&1
    for i in $(seq 1 90); do kubectl get ns "$ns" >/dev/null 2>&1 || break; sleep 2; done
    for i in $(seq 1 30); do kubectl create ns "$ns" >/dev/null 2>&1 && break; sleep 2; done
    # pods need the namespace's default ServiceAccount (created by kube-controller-manager)
    for i in $(seq 1 60); do kubectl -n "$ns" get sa default >/dev/null 2>&1 && break; sleep 2; done
  done
}
# recreate kube-controller-manager / kube-scheduler static pods to clear kubelet CrashLoopBackOff delays
# (they exit whenever the apiserver restarts and the backoff grows up to 5 minutes)
fresh_control_plane() {
  local d=/etc/kubernetes/manifests t=/root/.cka-cp-tmp; mkdir -p $t
  for c in kube-controller-manager kube-scheduler; do mv $d/$c.yaml $t/ 2>/dev/null; done
  for i in $(seq 1 30); do crictl ps --name 'kube-(controller-manager|scheduler)' -q | grep -q . || break; sleep 2; done
  for c in kube-controller-manager kube-scheduler; do mv $t/$c.yaml $d/ 2>/dev/null; done
  for i in $(seq 1 60); do
    [ "$(crictl ps --name 'kube-(controller-manager|scheduler)' -s Running -q | wc -l)" -ge 2 ] && break; sleep 2
  done
}
course_dir() { mkdir -p "/opt/course/$1"; rm -rf "/opt/course/$1"/*; chown -R candidate: /opt/course; }
