```yaml
apiVersion: v1
kind: LimitRange
metadata: {name: container-limits, namespace: s03-quota}
spec:
  limits:
  - type: Container
    default: {cpu: 200m, memory: 128Mi}         # default LIMIT
    defaultRequest: {cpu: 50m, memory: 32Mi}
    max: {cpu: 500m, memory: 256Mi}
```
```bash
ssh cka-cp1
k apply -f lr.yaml
k -n s03-quota create quota team-quota --hard=requests.cpu=500m,requests.memory=512Mi,limits.cpu=1,limits.memory=1Gi,pods=6
k -n s03-quota rollout restart deploy api       # LimitRange only applies to NEW pods at admission
k -n s03-quota get pod -o jsonpath='{range .items[*]}{.metadata.name} {.spec.containers[0].resources}{"\n"}{end}'
k -n s03-quota run oversized --image=nginx:1.27-alpine $do > o.yaml   # add limits.cpu: "1"
k create -f o.yaml 2> /opt/course/s03-quota/oversized.txt
k -n s03-quota describe quota team-quota
```
Traps: LimitRange/Quota don't change existing pods → a restart is needed. Once a ResourceQuota defines requests/limits, pods without resources are rejected — the LimitRange defaults solve this. The `kubectl run --limits` flag no longer exists; use YAML or `--overrides`. Error: `maximum cpu usage per Container is 500m, but limit is 1`.
