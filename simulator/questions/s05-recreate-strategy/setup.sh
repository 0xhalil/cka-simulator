course_dir s05-recreate
reset_ns s05-recreate
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: ledger, namespace: s05-recreate}
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate: {maxSurge: 1, maxUnavailable: 0}
  selector: {matchLabels: {app: ledger}}
  template:
    metadata: {labels: {app: ledger}}
    spec:
      containers:
      - name: app
        image: nginx:1.27-alpine
      - name: log-agent
        image: busybox:1.36
        command: ["sh", "-c", "while true; do echo shipping logs; sleep 30; done"]
YAML
wait_deploy s05-recreate ledger
kubectl -n s05-recreate get deploy ledger -o jsonpath='{.metadata.uid}' > /root/.s05-recreate-uid
chown -R candidate: /opt/course
