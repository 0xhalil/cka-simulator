cat > /opt/course/s08-vol/logger.yaml <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: logger
  namespace: s08-vol
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "while true; do echo \"$(date) s08-entry\" >> /var/log/app/app.log; sleep 2; done"]
    volumeMounts:
    - {name: shared, mountPath: /var/log/app}
  - name: reader
    image: busybox:1.36
    command: ["sh", "-c", "echo \"node=$(cat /node/hostname)\"; tail -f /input/app.log"]
    volumeMounts:
    - {name: shared, mountPath: /input, readOnly: true}
    - {name: node-name, mountPath: /node/hostname, readOnly: true}
  volumes:
  - name: shared
    emptyDir:
      medium: Memory
      sizeLimit: 32Mi
  - name: node-name
    hostPath:
      path: /etc/hostname
      type: File
YAML
chown candidate: /opt/course/s08-vol/logger.yaml
kubectl apply -f /opt/course/s08-vol/logger.yaml
kubectl -n s08-vol wait --for=condition=Ready pod/logger --timeout=90s
sleep 5
