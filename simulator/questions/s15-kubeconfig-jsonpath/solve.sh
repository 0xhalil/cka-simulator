D=/opt/course/s15-kcfg; K="--kubeconfig $D/my-kube-config"
kubectl config view $K -o jsonpath='{.users[*].name}' > $D/users.txt
kubectl config view $K -o jsonpath='{.contexts[?(@.context.user=="aws-user")].name}' > $D/aws-context.txt
kubectl config view $K -o jsonpath='{.contexts[?(@.context.namespace=="finance")].name}' > $D/finance.txt
C=$(kubectl config view $K -o jsonpath='{.contexts[?(@.name=="research")].context.cluster}')
kubectl config view $K -o jsonpath="{.clusters[?(@.name==\"$C\")].cluster.server}" > $D/research-server.txt
kubectl config use-context research $K
for f in $D/*.txt; do echo "$f: $(cat $f)"; done
