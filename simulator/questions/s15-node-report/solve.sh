D=/opt/course/s15-nodes
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.capacity.cpu}{"\t"}{.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' > $D/nodes.txt
kubectl get nodes -o custom-columns=NODE:.metadata.name,TAINT_KEY:.spec.taints[*].key,TAINT_EFFECT:.spec.taints[*].effect > $D/taints.txt
kubectl -n kube-system get pod -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u > $D/images.txt
cat $D/*
