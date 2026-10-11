course_dir s09-netns
reset_ns s09-netns
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata: {name: tracer, namespace: s09-netns, labels: {app: tracer}}
spec:
  nodeSelector: {kubernetes.io/hostname: cka-w1}
  terminationGracePeriodSeconds: 1
  containers:
  - name: tracer
    image: nginx:1.27-alpine
    resources: {requests: {cpu: 5m, memory: 16Mi}}
YAML
kubectl -n s09-netns wait --for=condition=Ready pod/tracer --timeout=120s >/dev/null
