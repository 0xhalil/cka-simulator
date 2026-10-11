Traps:
- `kubectl logs deploy/worker` shows the logs of only **one** Pod.
- `-l app=worker` also matches the `worker-legacy` Pods — use the Deployment's actual selector (`app=worker,tier=batch`).
- Each Pod has 2 containers → `--all-containers`; `--prefix` to tag each line with its source.
- **Sneakiest trap:** with a selector (`-l`), `kubectl logs` by default returns only the **last 10 lines** from each container (the `--tail` default is 10 with a selector). Use `--tail=-1` for all logs.

```bash
ssh cka-cp1
k -n s04-agg get deploy worker -o jsonpath='{.spec.selector.matchLabels}'
k -n s04-agg get pod --show-labels
k -n s04-agg logs -l app=worker,tier=batch --all-containers --prefix --tail=-1 > /opt/course/s04-agg/worker.log
grep -c WARN /opt/course/s04-agg/worker.log > /opt/course/s04-agg/warn-count.txt
```
Note: with `-l -f`, the concurrent stream limit is `--max-log-requests=5`.
