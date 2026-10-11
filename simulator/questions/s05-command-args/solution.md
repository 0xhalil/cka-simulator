Docker ↔ Kubernetes mapping: `ENTRYPOINT` ↔ `command`, `CMD` ↔ `args`. Setting `command` completely overrides the ENTRYPOINT.

**1. sleeper** — `command: ["sleep 3600"]` is a single array element → the runtime looks for a binary named `"sleep 3600"` (`executable file not found`). Each argument must be a separate element:
```bash
ssh cka-cp1
k -n s05-cmd describe pod -l app=sleeper | grep -A3 'Last State'
k -n s05-cmd edit deploy sleeper
```
```yaml
        command: ["sleep", "3600"]       # or command: ["sleep"] + args: ["3600"]
```

**2. cache** — set only `args` (CMD), not `command` (ENTRYPOINT):
```bash
k -n s05-cmd run cache --image=redis:7-alpine -- redis-server --port 6380 --maxmemory 32mb
#   (kubectl run --  ... => args;  --command -- ... => command)
k -n s05-cmd exec cache -- redis-cli -p 6380 config get maxmemory
k -n s05-cmd exec cache -- ps     # runs as the redis user
```
Trap: using `kubectl run ... --command -- redis-server ...` or `command:` in YAML skips `docker-entrypoint.sh` → redis runs as root.
