NE="ds node-exporter-lite -n s03-ds"; LS="ds log-shipper -n s03-ds"
nodes_of() { kubectl -n s03-ds get pod -l app=$1 -o jsonpath='{range .items[?(@.status.phase=="Running")]}{.spec.nodeName}{"\n"}{end}' | sort | tr '\n' ' '; }
check "cp-taints.txt contains the taint of cka-cp1" 'grep -Eq "^node-role\.kubernetes\.io/control-plane=?:NoSchedule$" /opt/course/s03-ds/cp-taints.txt'
check "node-exporter-lite has a ready Pod on both nodes (cka-cp1 and cka-w1)" \
  'for i in $(seq 1 15); do [ "$(jp $NE "{.status.desiredNumberScheduled}/{.status.numberReady}")" = 2/2 ] && [ "$(nodes_of node-exporter-lite)" = "cka-cp1 cka-w1 " ] && exit 0; sleep 2; done; exit 1'
check "DaemonSet log-shipper uses image busybox:1.36 with requests cpu 5m / memory 16Mi" \
  '[ "$(jp $LS "{.spec.template.spec.containers[0].image}|{.spec.template.spec.containers[0].resources.requests.cpu}|{.spec.template.spec.containers[0].resources.requests.memory}")" = "busybox:1.36|5m|16Mi" ]'
check "log-shipper mounts hostPath /var/log read-only at /host/log" \
  'kubectl get $LS -o json | jq -e ".spec.template.spec as \$s | (\$s.containers[0].volumeMounts[] | select(.mountPath==\"/host/log\" and .readOnly==true) | .name) as \$v | \$s.volumes[] | select(.name==\$v and .hostPath.path==\"/var/log\")"'
check "log-shipper runs only on the control plane node (1 ready Pod on cka-cp1, none on cka-w1)" \
  'for i in $(seq 1 15); do [ "$(jp $LS "{.status.desiredNumberScheduled}/{.status.numberReady}")" = 1/1 ] && [ "$(nodes_of log-shipper)" = "cka-cp1 " ] && exit 0; sleep 2; done; exit 1'
check "log-shipper Pod sees the node's /var/log content below /host/log" \
  'p=$(kubectl -n s03-ds get pod -l app=log-shipper -o name | head -1); [ -n "$p" ] && kubectl -n s03-ds exec $p -- ls /host/log | grep -q pods'
guard "node taints unchanged (cka-cp1 control-plane taint present, cka-w1 untainted)" \
  'jp node cka-cp1 "{.spec.taints[*].key}" | grep -q node-role.kubernetes.io/control-plane && [ -z "$(jp node cka-w1 "{.spec.taints}")" ]'
