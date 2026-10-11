The operations team uses the kubeconfig file `/opt/course/s07-kubeconfig/ops.kubeconfig` to access **cluster1** as user **`s07-ops`** via the context **`ops`**. Since a recent "cleanup" the file no longer works.

1. Repair `/opt/course/s07-kubeconfig/ops.kubeconfig` so that `kubectl --kubeconfig /opt/course/s07-kubeconfig/ops.kubeconfig get pods -n kube-system` works **without** passing `--context`. The ops credentials (certificate and key) are located in `/opt/course/s07-kubeconfig/`.
   - Authentication must happen as `s07-ops` — do **not** use any other credentials (e.g. the admin ones).
   - Do not remove the other context (`staging`) from the file.
   - Do not modify `~/.kube/config`.
2. Write the username the API server sees for this kubeconfig (determined with kubectl) into `/opt/course/s07-kubeconfig/whoami.txt`.
