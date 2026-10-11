The Pod `payment-gw` in namespace `s04-logs` runs several containers. Security asked for some log extracts:

1. Write **only the lines containing `ERROR`** from the logs of the container `audit-agent` into `/opt/course/s04-logs/audit-errors.log`.
2. Write the **last 5 log lines** of the container `gateway` into `/opt/course/s04-logs/gateway-tail.log`.
3. Write the **first 3 log lines** of the container `audit-agent`, each prefixed with the timestamp Kubernetes recorded for that line (as `kubectl` can show it), into `/opt/course/s04-logs/audit-ts.log`.

The files must contain the log lines exactly as `kubectl` prints them (no additional output).
