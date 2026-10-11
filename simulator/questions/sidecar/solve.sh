kubectl -n sidecar patch deploy logger-app --type=strategic -p '
spec:
  template:
    spec:
      volumes: [{name: logs, emptyDir: {}}]
      initContainers:
      - name: sidecar
        image: busybox:1.36
        restartPolicy: Always
        command: ["/bin/sh", "-c", "tail -n+1 -F /var/log/app.log"]
        volumeMounts: [{name: logs, mountPath: /var/log}]
      containers:
      - name: app
        volumeMounts: [{name: logs, mountPath: /var/log}]
'
kubectl -n sidecar rollout status deploy logger-app
