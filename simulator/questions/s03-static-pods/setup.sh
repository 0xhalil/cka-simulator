M=/etc/kubernetes/manifests
on cka-w1 "rm -f $M/s03-static-web.yaml $M/s03-healthcheck.yaml; for f in $M/*; do grep -qs 'namespace: s03-static' \"\$f\" && rm -f \"\$f\"; done; true"
reset_ns s03-static
course_dir s03-static
B=$(sed "s/__TS__/$(date +%s)/" <<'YAML' | base64 -w0
apiVersion: v1
kind: Pod
metadata:
  name: cpu-burner
  namespace: s03-static
  labels: {app: cpu-burner}
  annotations: {cka.local/build: "__TS__"}
spec:
  terminationGracePeriodSeconds: 2
  containers:
  - name: burner
    image: busybox:1.36
    command: ["sh", "-c", "while true; do echo burning; sleep 20; done"]
    resources: {requests: {cpu: 5m, memory: 8Mi}}
YAML
)
on cka-w1 "echo $B | base64 -d > $M/s03-healthcheck.yaml"
for i in $(seq 1 45); do [ "$(kubectl -n s03-static get pod cpu-burner-cka-w1 -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null)" = true ] && break; sleep 2; done
kubectl -n s03-static get pod
