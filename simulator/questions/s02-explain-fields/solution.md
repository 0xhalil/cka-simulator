`kubectl explain` is the fastest way to find fields; `--recursive` shows the whole tree, filter with `grep`:

```bash
ssh cka-cp1
k explain pod.spec | grep -iE 'process|service|grace|alias' 
k explain pod.spec.hostAliases
k explain deploy.spec | grep -iE -A2 'revisionHistory|minReady|progressDeadline'
k explain deploy.spec --recursive | less
```

```bash
k -n s02-explain run toolbox --image=busybox:1.36 $do --command -- sleep 3600 > toolbox.yaml
```
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: toolbox
  namespace: s02-explain
spec:
  shareProcessNamespace: true        # single PID namespace -> 'pause' visible with ps
  enableServiceLinks: false          # SERVICE_HOST/PORT env vars are not injected
  terminationGracePeriodSeconds: 5
  hostAliases:                       # kubelet adds these to /etc/hosts (don't edit the file by hand!)
  - ip: 10.10.10.10
    hostnames: [legacy-db, legacy-db.internal]
  containers:
  - name: shell                      # trap: `k run` names the container 'toolbox'
    image: busybox:1.36
    command: ["sleep", "3600"]
```
```bash
k apply -f toolbox.yaml
k -n s02-explain exec toolbox -- cat /etc/hosts
```
```
HISTORY=spec.revisionHistoryLimit
READY=spec.minReadySeconds
DEADLINE=spec.progressDeadlineSeconds
```
