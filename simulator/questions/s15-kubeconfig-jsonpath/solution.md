`kubectl config view` reads the kubeconfig file; another file can be given with `--kubeconfig`. Filter expressions `?(@.field=="value")` search within a list.

```bash
ssh cka-cp1
K="--kubeconfig /opt/course/s15-kcfg/my-kube-config"
k config view $K -o jsonpath='{.users[*].name}' > /opt/course/s15-kcfg/users.txt
k config view $K -o jsonpath='{.contexts[?(@.context.user=="aws-user")].name}' > /opt/course/s15-kcfg/aws-context.txt
k config view $K -o jsonpath='{.contexts[?(@.context.namespace=="finance")].name}' > /opt/course/s15-kcfg/finance.txt

# two steps: context -> cluster name -> server
k config view $K -o jsonpath='{.contexts[?(@.name=="research")].context.cluster}'      # test-cluster-1
k config view $K -o jsonpath='{.clusters[?(@.name=="test-cluster-1")].cluster.server}' > /opt/course/s15-kcfg/research-server.txt

k config use-context research $K
```
Traps: the context name (`research`) and the cluster name (`test-cluster-1`) are different. Running `use-context` without `$K` messes up your own kubeconfig. `kubectl config view` hides certificate data by default (`--raw` isn't needed; there are file paths here).
