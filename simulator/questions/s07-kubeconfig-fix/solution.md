The kubeconfig has three errors:
1. `cluster1` server port is **6444** → the apiserver listens on **6443**.
2. Context `ops` points to the non-existent user `ops` → the correct user entry is **`ops-admin`**.
3. The `client-key` path of user `ops-admin` is `ops-key.pem` → the file is actually **`ops.key`**.
Also `current-context: staging` → must be `ops`.

```bash
ssh cka-cp1
cd /opt/course/s07-kubeconfig
K="kubectl --kubeconfig ops.kubeconfig"
$K config view                        # see the errors
grep server ~/.kube/config            # correct address/port: https://192.168.104.6:6443
$K config set-cluster cluster1 --server=https://192.168.104.6:6443
$K config set-credentials ops-admin --client-key=/opt/course/s07-kubeconfig/ops.key
$K config set-context ops --user=ops-admin
$K config use-context ops
$K -n kube-system get pods
$K auth whoami -o jsonpath='{.status.userInfo.username}' > whoami.txt   # s07-ops
```
(You can do the same with `vim ops.kubeconfig`.) Context name ≠ user name: a context just references the `cluster` + `user` + `namespace` triple by name.
