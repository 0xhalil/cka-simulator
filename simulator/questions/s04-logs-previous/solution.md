By default `kubectl logs` shows the logs of the **currently running** container instance — here only the "degraded mode" lines are visible. For the logs of the previous, crashed instance you need `--previous` (`-p`). The kubelet only keeps the logs of the one previous instance; if the Pod is deleted/recreated, the evidence is lost.

```bash
ssh cka-cp1
k -n s04-crash get pod                      # RESTARTS 1
P=$(k -n s04-crash get pod -l app=ledger -o name)
k -n s04-crash logs $P                      # current instance
k -n s04-crash logs $P --previous > /opt/course/s04-crash/crash.log
k -n s04-crash get $P -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}' > /opt/course/s04-crash/exit-code.txt
# or: k -n s04-crash describe $P   -> Last State: Terminated, Exit Code: N
grep FATAL /opt/course/s04-crash/crash.log      # migration number -> migration.txt
```
