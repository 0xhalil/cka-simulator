course_dir s07-sec
reset_ns s07-sec
cat > /opt/course/s07-sec/secure-app.yaml <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: s07-sec
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /data/app.log; sleep 10; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  - name: clock
    image: busybox:1.36
    command: ["sleep", "1d"]
  volumes:
  - name: data
    emptyDir: {}
YAML
chown -R candidate: /opt/course/s07-sec
kubectl apply -f /opt/course/s07-sec/secure-app.yaml >/dev/null
kubectl -n s07-sec wait --for=condition=Ready pod/secure-app --timeout=90s >/dev/null
