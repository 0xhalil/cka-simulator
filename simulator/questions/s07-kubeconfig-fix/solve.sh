D=/opt/course/s07-kubeconfig
K="kubectl --kubeconfig $D/ops.kubeconfig"
IP=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | sed -E 's#https://([^:]+):.*#\1#')
$K config set-cluster cluster1 --server=https://$IP:6443
$K config set-credentials ops-admin --client-key=$D/ops.key
$K config set-context ops --user=ops-admin
$K config use-context ops
$K auth whoami -o jsonpath='{.status.userInfo.username}' > $D/whoami.txt
chown -R candidate: $D
