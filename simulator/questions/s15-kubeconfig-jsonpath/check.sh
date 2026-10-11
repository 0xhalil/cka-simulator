D=/opt/course/s15-kcfg; K="--kubeconfig $D/my-kube-config"
q() { kubectl config view $K -o jsonpath="$1" 2>/dev/null; }
set_eq() { [ -s "$1" ] && [ "$(tr -s " \t\n" "\n\n\n" < $1 | grep -v "^$" | sort | tr "\n" " ")" = "$(echo "$2" | tr " " "\n" | grep -v "^$" | sort | tr "\n" " ")" ]; }
check "users.txt lists all users" 'set_eq $D/users.txt "$(q "{.users[*].name}")"'
check "aws-context.txt names the context using aws-user" '[ "$(tr -d "[:space:]" < $D/aws-context.txt)" = "$(q "{.contexts[?(@.context.user==\"aws-user\")].name}")" ]'
check "finance.txt lists the contexts with namespace finance" 'set_eq $D/finance.txt "$(q "{.contexts[?(@.context.namespace==\"finance\")].name}")"'
check "research-server.txt contains the server of cluster test-cluster-1" '[ "$(tr -d "[:space:]" < $D/research-server.txt)" = "$(q "{.clusters[?(@.name==\"test-cluster-1\")].cluster.server}")" ]'
check "current-context of my-kube-config is research" '[ "$(q "{.current-context}")" = research ]'
guard "own kubeconfig (/etc/kubernetes/admin.conf) still points to cluster1" 'kubectl get node cka-cp1'
