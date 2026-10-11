- `emptyDir.medium: Memory` → tmpfs (RAM). If `sizeLimit` is exceeded the Pod is evicted; a memory-backed emptyDir also counts against the container memory limit.
- `hostPath.type: File` → the path must exist on the node as a **file** (otherwise the Pod won't start). A single file can be mounted too.
- If `app.log` doesn't exist yet when `reader` starts, `tail -f` waits (busybox tail reads once the file appears); use `tail -F` if needed.

```yaml
apiVersion: v1
kind: Pod
metadata: {name: logger, namespace: s08-vol}
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh","-c","while true; do echo \"$(date) s08-entry\" >> /var/log/app/app.log; sleep 2; done"]
    volumeMounts:
    - {name: shared, mountPath: /var/log/app}
  - name: reader
    image: busybox:1.36
    command: ["sh","-c","echo \"node=$(cat /node/hostname)\"; tail -f /input/app.log"]
    volumeMounts:
    - {name: shared, mountPath: /input, readOnly: true}
    - {name: node-name, mountPath: /node/hostname, readOnly: true}
  volumes:
  - name: shared
    emptyDir: {medium: Memory, sizeLimit: 32Mi}
  - name: node-name
    hostPath: {path: /etc/hostname, type: File}
```
```bash
ssh cka-cp1
k apply -f /opt/course/s08-vol/logger.yaml
k -n s08-vol logs logger -c reader
k -n s08-vol exec logger -c writer -- df -h /var/log/app      # tmpfs 32M
```
