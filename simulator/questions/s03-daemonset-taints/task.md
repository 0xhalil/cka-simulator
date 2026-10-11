Work in namespace `s03-ds`.

1. Write the taint(s) of node `cka-cp1` into `/opt/course/s03-ds/cp-taints.txt`, one per line, in the format `<key>:<effect>`.
2. The DaemonSet `node-exporter-lite` should run one Pod on **every** node of the cluster, including the control plane, but currently it only runs on `cka-w1`. Fix it.
3. Create a new DaemonSet `log-shipper` (Pod label `app=log-shipper`) that:
   - runs **only** on control plane nodes — never on worker nodes,
   - uses image `busybox:1.36` with command `sh -c "tail -F /host/log/syslog"`,
   - requests CPU `5m` and memory `16Mi`,
   - mounts the node's directory `/var/log` **read-only** at `/host/log`.

Do not add, remove or change any node taints.
