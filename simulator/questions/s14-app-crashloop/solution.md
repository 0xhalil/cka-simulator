Three Deployments, three different errors — each shows a different pod state:

| Deployment | Symptom | Cause | Fix |
|---|---|---|---|
| `ledger-api` | Running but RESTARTS keeps increasing, event: `Liveness probe failed ... connect: connection refused` | liveness probe port 8080, nginx listens on 80 | probe port `80` (or `http`) |
| `ledger-worker` | `CreateContainerConfigError`, event: `couldn't find key LOG_LEVEL in ConfigMap` | ConfigMap key is `log_level` | `configMapKeyRef.key: log_level` (or add a `LOG_LEVEL` key to the CM) |
| `ledger-cache` | `CrashLoopBackOff`, `Last State: Terminated, Reason: OOMKilled, Exit Code 137` | cache loads 24Mi into memory, memory limit is only 16Mi | raise the memory limit (e.g. 64Mi) |

Trap: a pod with a failing liveness probe often shows `Running 1/1` — look at the RESTARTS column and the `describe` events. For OOMKilled: `kubectl describe pod` → `Last State`.

```bash
k -n s14-ledger get po
k -n s14-ledger describe po -l app=ledger-api | grep -A3 -i liveness
k -n s14-ledger edit deploy ledger-api          # livenessProbe.httpGet.port: 80
k -n s14-ledger describe po -l app=ledger-worker | tail
k -n s14-ledger get cm ledger-config -o yaml
k -n s14-ledger edit deploy ledger-worker       # key: log_level
k -n s14-ledger describe po -l app=ledger-cache | grep -A4 "Last State"
k -n s14-ledger set resources deploy ledger-cache --limits=memory=64Mi
k -n s14-ledger get po -w
```
