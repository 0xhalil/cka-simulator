In a multi-container Pod, `kubectl logs` needs `-c <container>` (otherwise it picks the default container or errors out). Trap: the `gateway` and `metrics` containers also print `ERROR` lines — grepping with `--all-containers` gives the wrong result.

```bash
ssh cka-cp1
k -n s04-logs get pod payment-gw -o jsonpath='{.spec.containers[*].name}'
k -n s04-logs logs payment-gw -c audit-agent | grep ERROR > /opt/course/s04-logs/audit-errors.log
k -n s04-logs logs payment-gw -c gateway --tail=5 > /opt/course/s04-logs/gateway-tail.log
k -n s04-logs logs payment-gw -c audit-agent --timestamps | head -3 > /opt/course/s04-logs/audit-ts.log
```
`--timestamps` prefixes each line with the RFC3339 timestamp recorded by the container runtime; `--tail=N` gives the last N lines, `--since=5m` the last 5 minutes.
