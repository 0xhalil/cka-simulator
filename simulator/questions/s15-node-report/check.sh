D=/opt/course/s15-nodes
norm() { sed 's/[[:space:]]*$//' | grep -v '^$'; }
ws() { awk '{$1=$1};1' | grep -v '^$'; }
check "nodes.txt has <name>TAB<cpu>TAB<InternalIP> for every node" '[ -s $D/nodes.txt ] && diff <(norm < $D/nodes.txt) <(kubectl get nodes -o jsonpath="{range .items[*]}{.metadata.name}{\"\t\"}{.status.capacity.cpu}{\"\t\"}{.status.addresses[?(@.type==\"InternalIP\")].address}{\"\n\"}{end}" | norm)'
check "taints.txt lists NODE, TAINT_KEY, TAINT_EFFECT for every node" '[ -s $D/taints.txt ] && diff <(ws < $D/taints.txt) <(kubectl get nodes -o custom-columns=NODE:.metadata.name,TAINT_KEY:.spec.taints[*].key,TAINT_EFFECT:.spec.taints[*].effect | ws)'
check "images.txt lists the distinct kube-system container images, sorted" '[ -s $D/images.txt ] && diff <(norm < $D/images.txt) <(kubectl -n kube-system get pod -o jsonpath="{.items[*].spec.containers[*].image}" | tr " " "\n" | grep -v "^$" | sort -u)'
