```bash
ssh cka-cp1
k -n sidecar edit deploy logger-app
```
```yaml
    spec:
      volumes:
      - name: logs
        emptyDir: {}
      initContainers:
      - name: sidecar
        image: busybox:1.36
        restartPolicy: Always          # native sidecar
        command: ["/bin/sh", "-c", "tail -n+1 -F /var/log/app.log"]
        volumeMounts: [{name: logs, mountPath: /var/log}]
      containers:
      - name: app
        ...
        volumeMounts: [{name: logs, mountPath: /var/log}]
```
```bash
k -n sidecar logs deploy/logger-app -c sidecar
```
