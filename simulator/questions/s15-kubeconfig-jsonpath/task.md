A colleague left the kubeconfig file `/opt/course/s15-kcfg/my-kube-config`. Use `kubectl config view` with JSONPath (the file's credentials do not work — don't try to connect to these clusters).

1. Write the names of **all users** defined in that file, space separated, into `/opt/course/s15-kcfg/users.txt`.
2. Write the name of the **context that uses the user `aws-user`** into `/opt/course/s15-kcfg/aws-context.txt`.
3. Write the names of all contexts whose default **namespace is `finance`**, space separated, into `/opt/course/s15-kcfg/finance.txt`.
4. Write the **server URL** of the cluster that the context `research` points to into `/opt/course/s15-kcfg/research-server.txt`.
5. Change the **current context of that file** (not of your own kubeconfig) to `research`.
