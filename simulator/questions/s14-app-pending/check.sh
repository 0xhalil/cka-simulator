stable() {  # stable <ns> <deploy> <replicas>: available, all Pods Ready and at most 1 restart and none during 15s
  kubectl -n $1 wait --for=condition=available deploy/$2 --timeout=30s || return 1
  local sel; sel=$(kubectl -n $1 get deploy $2 -o go-template='{{range $k,$v := .spec.selector.matchLabels}}{{$k}}={{$v}},{{end}}' | sed 's/,$//')
  local r1; r1=$(kubectl -n $1 get po -l "$sel" -o jsonpath='{range .items[*]}{.metadata.name}:{.status.containerStatuses[*].restartCount} {end}')
  sleep 15
  local r2; r2=$(kubectl -n $1 get po -l "$sel" -o jsonpath='{range .items[*]}{.metadata.name}:{.status.containerStatuses[*].restartCount} {end}')
  ! echo "$r2" | grep -Eq ':([2-9]|[1-9][0-9]+)( |$)' && [ "$r1" = "$r2" ] && [ "$(kubectl -n $1 get deploy $2 -o jsonpath='{.status.readyReplicas}')" = "$3" ]
}
N=s14-orbit
check "Deployment orbit-web has 2 ready, stable replicas" 'stable $N orbit-web 2'
check "PVC orbit-data is Bound, 100Mi, via an existing StorageClass" 'P=$(jp pvc orbit-data -n $N "{.status.phase}|{.spec.resources.requests.storage}|{.spec.storageClassName}"); [ "${P%%|*}" = Bound ] && echo "$P" | grep -q "|100Mi|" && kubectl get sc "${P##*|}"'
check "Deployment orbit-db is available and uses PVC orbit-data at /data" 'stable $N orbit-db 1 && [ "$(jp deploy orbit-db -n $N "{.spec.template.spec.volumes[?(@.persistentVolumeClaim.claimName==\"orbit-data\")].name}")" = "$(jp deploy orbit-db -n $N "{.spec.template.spec.containers[0].volumeMounts[?(@.mountPath==\"/data\")].name}")" ]'
check "orbit-db stores data on the PVC (redis write + appendonly file in /data)" 'kubectl -n $N exec deploy/orbit-db -- redis-cli set s14 ok | grep -q OK && kubectl -n $N exec deploy/orbit-db -- sh -c "mount | grep -q \" /data \" && ls /data | grep -q appendonly"'
guard "all containers keep CPU and memory requests" '[ -n "$(jp deploy orbit-web -n $N "{.spec.template.spec.containers[0].resources.requests.cpu}")" ] && [ -n "$(jp deploy orbit-web -n $N "{.spec.template.spec.containers[0].resources.requests.memory}")" ] && [ -n "$(jp deploy orbit-db -n $N "{.spec.template.spec.containers[0].resources.requests.cpu}")" ]'
guard "Node cka-w1 hostname label untouched and no node labeled cka-worker1" '[ "$(jp node cka-w1 "{.metadata.labels.kubernetes\.io/hostname}")" = cka-w1 ] && [ -z "$(kubectl get nodes -l kubernetes.io/hostname=cka-worker1 -o name)" ]'
