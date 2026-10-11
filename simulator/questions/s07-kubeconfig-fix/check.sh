D=/opt/course/s07-kubeconfig
KC() { timeout 20 kubectl --kubeconfig $D/ops.kubeconfig --request-timeout=8s "$@" </dev/null; }
check "ops is the current context" '[ "$(KC config current-context)" = ops ]'
check "kubectl with ops.kubeconfig can list pods in kube-system" 'KC -n kube-system get pods'
check "ops.kubeconfig authenticates as s07-ops" '[ "$(KC auth whoami -o jsonpath={.status.userInfo.username})" = s07-ops ]'
check "whoami.txt contains s07-ops" 'grep -qw s07-ops $D/whoami.txt && ! grep -q kubernetes-admin $D/whoami.txt'
guard "context staging still exists" 'KC config get-contexts staging'
guard "candidate ~/.kube/config still works" 'sudo -u candidate kubectl --request-timeout=8s get ns default'
