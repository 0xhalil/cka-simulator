course_dir s05-resize
reset_ns s05-resize
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata: {name: metrics-agent, namespace: s05-resize, labels: {app: metrics-agent}}
spec:
  containers:
  - name: agent
    image: nginx:1.27-alpine
    resizePolicy:
    - {resourceName: cpu, restartPolicy: NotRequired}
    - {resourceName: memory, restartPolicy: RestartContainer}
    resources:
      requests: {cpu: 50m, memory: 32Mi}
      limits: {cpu: 100m, memory: 64Mi}
YAML
kubectl -n s05-resize wait --for=condition=Ready pod/metrics-agent --timeout=120s >/dev/null
kubectl -n s05-resize get pod metrics-agent -o jsonpath='{.metadata.uid}' > /root/.s05-resize-uid
chown -R candidate: /opt/course
