reset_ns s04-top
course_dir s04-top
roles=$(printf 'cpu\nmem\nidle\nidle\n' | shuf)
i=0
for r in $roles; do
  i=$((i+1)); name=analytics-$(printf '%s' "$i$RANDOM" | md5sum | cut -c1-5)
  case $r in
    cpu)  cmd='while true; do :; done' ;;
    mem)  cmd='dd if=/dev/zero of=/cache/blob bs=1M count=48 2>/dev/null; sleep 360000' ;;
    idle) cmd='sleep 360000' ;;
  esac
  cat <<YAML | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata: {name: $name, namespace: s04-top, labels: {app: analytics}}
spec:
  terminationGracePeriodSeconds: 1
  containers:
  - name: worker
    image: busybox:1.36
    command: ["sh", "-c", "$cmd"]
    resources:
      requests: {cpu: 5m, memory: 8Mi}
      limits: {cpu: 100m, memory: 96Mi}
    volumeMounts: [{name: cache, mountPath: /cache}]
  - name: proxy
    image: busybox:1.36
    command: ["sleep", "360000"]
    resources: {requests: {cpu: 1m, memory: 4Mi}, limits: {cpu: 20m, memory: 16Mi}}
  volumes:
  - name: cache
    emptyDir: {medium: Memory, sizeLimit: 64Mi}
YAML
done
kubectl -n s04-top wait --for=condition=Ready pod --all --timeout=120s >/dev/null
true
