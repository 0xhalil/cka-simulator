echo cka-w1:/etc/kubernetes/manifests/s03-healthcheck.yaml > /opt/course/s03-static/burner-source.txt
B=$(base64 -w0 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: s03-static-web
  namespace: s03-static
  labels: {app: static-web}
spec:
  containers:
  - name: web
    image: nginx:1.27-alpine
    resources: {requests: {cpu: 10m, memory: 16Mi}}
YAML
)
on cka-w1 "rm -f /etc/kubernetes/manifests/s03-healthcheck.yaml; echo $B | base64 -d > /etc/kubernetes/manifests/s03-static-web.yaml"
for i in $(seq 1 30); do kubectl -n s03-static get pod s03-static-web-cka-w1 && break; sleep 2; done
kubectl -n s03-static wait --for=condition=Ready pod/s03-static-web-cka-w1 --timeout=60s
