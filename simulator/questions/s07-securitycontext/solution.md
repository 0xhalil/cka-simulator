Pod-level `securityContext` applies to all containers; container-level **overrides** it (`clock` → `runAsUser: 0`).
`capabilities`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation` are **container-level only** fields. A running Pod's securityContext can't be changed → delete & recreate.

```yaml
spec:
  securityContext:          # pod-level
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    ...
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
  - name: clock
    ...
    securityContext:
      runAsUser: 0
      capabilities:
        add: ["SYS_TIME"]
```
```bash
ssh cka-cp1
vim /opt/course/s07-sec/secure-app.yaml
k replace --force -f /opt/course/s07-sec/secure-app.yaml
k -n s07-sec exec secure-app -c app -- id > /opt/course/s07-sec/id.txt
#   uid=1000 gid=3000 groups=2000,3000
k -n s07-sec exec secure-app -c app -- touch /x          # Read-only file system
k -n s07-sec exec secure-app -c clock -- grep Cap /proc/1/status
```
