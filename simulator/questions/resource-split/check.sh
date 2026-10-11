D="deploy web-portal -n resources"
tocpu() { case $1 in *m) echo ${1%m};; '') echo 0;; *) awk -v v=$1 'BEGIN{print v*1000}';; esac; }
tomem() { local v=$1; case $v in *Ki) echo $(( ${v%Ki} * 1024 ));; *Mi) echo $(( ${v%Mi} * 1048576 ));; *Gi) echo $(( ${v%Gi} * 1073741824 ));; *k) echo $(( ${v%k} * 1000 ));; *M) echo $(( ${v%M} * 1000000 ));; *G) echo $(( ${v%G} * 1000000000 ));; '') echo 0;; *) echo $v;; esac; }
IC=$(jp $D '{.spec.template.spec.initContainers[0].resources.requests.cpu}')
IM=$(jp $D '{.spec.template.spec.initContainers[0].resources.requests.memory}')
MC=$(jp $D '{.spec.template.spec.containers[0].resources.requests.cpu}')
MM=$(jp $D '{.spec.template.spec.containers[0].resources.requests.memory}')
# what everything else on cka-w1 requests
other() {
  kubectl get pod -A --field-selector spec.nodeName=cka-w1,status.phase!=Succeeded,status.phase!=Failed -o json | jq -r --arg r "$1" '
    [.items[] | select(.metadata.namespace != "resources") | [.spec.containers[].resources.requests[$r] // "0"]] | flatten | .[]'
}
sum_cpu=0; for v in $(other cpu); do sum_cpu=$((sum_cpu + $(tocpu $v))); done
sum_mem=0; for v in $(other memory); do sum_mem=$((sum_mem + $(tomem $v))); done
A_CPU=$(tocpu $(jp node cka-w1 '{.status.allocatable.cpu}')); A_MEM=$(tomem $(jp node cka-w1 '{.status.allocatable.memory}'))
FREE_CPU=$((A_CPU - sum_cpu)); FREE_MEM=$((A_MEM - sum_mem))
check "init container and main container have identical requests" "[ -n \"$MC\" ] && [ -n \"$MM\" ] && [ \"$IC/$IM\" = \"$MC/$MM\" ]"
check "3 replicas Running on cka-w1" "[ \"\$(kubectl -n resources get pod -l app=web-portal --field-selector status.phase=Running -o jsonpath='{range .items[*]}{.spec.nodeName}{\"\\n\"}{end}' | grep -c cka-w1)\" = 3 ] && [ \"\$(jp $D '{.status.readyReplicas}')\" = 3 ]"
check "CPU request per Pod is a fair share (>= 50% of an even split of free CPU, total fits)" "[ $(tocpu $MC) -ge $((FREE_CPU / 6)) ] && [ $(( $(tocpu $MC) * 3 )) -le $FREE_CPU ]"
check "memory request per Pod is a fair share (>= 50% of an even split of free memory, total fits)" "[ $(tomem $MM) -ge $((FREE_MEM / 6)) ] && [ $(( $(tomem $MM) * 3 )) -le $FREE_MEM ]"
guard "nodeSelector and images unchanged" "[ \"\$(jp $D '{.spec.template.spec.nodeSelector.kubernetes\\.io/hostname}|{.spec.template.spec.containers[0].image}|{.spec.template.spec.initContainers[0].image}')\" = 'cka-w1|nginx:1.27-alpine|busybox:1.36' ]"
echo "INFO free on cka-w1 excluding web-portal: cpu=${FREE_CPU}m mem=$((FREE_MEM/1048576))Mi; requested per pod cpu=$MC mem=$MM"
