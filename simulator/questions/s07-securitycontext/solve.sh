cat > /opt/course/s07-sec/secure-app.yaml <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: s07-sec
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /data/app.log; sleep 10; done"]
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: data
      mountPath: /data
  - name: clock
    image: busybox:1.36
    command: ["sleep", "1d"]
    securityContext:
      runAsUser: 0
      capabilities:
        add: ["SYS_TIME"]
  volumes:
  - name: data
    emptyDir: {}
YAML
kubectl replace --force -f /opt/course/s07-sec/secure-app.yaml
kubectl -n s07-sec wait --for=condition=Ready pod/secure-app --timeout=90s
kubectl -n s07-sec exec secure-app -c app -- id > /opt/course/s07-sec/id.txt
chown -R candidate: /opt/course/s07-sec
