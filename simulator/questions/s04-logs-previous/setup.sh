reset_ns s04-crash
course_dir s04-crash
T=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')
M=$(printf '%04d' $(( $(od -An -N2 -tu2 /dev/urandom) % 900 + 50 )))
X=$(( $(od -An -N1 -tu1 /dev/urandom) % 5 + 3 ))
cat <<YAML | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: ledger, namespace: s04-crash}
spec:
  replicas: 1
  selector: {matchLabels: {app: ledger}}
  template:
    metadata: {labels: {app: ledger}}
    spec:
      terminationGracePeriodSeconds: 1
      containers:
      - name: ledger
        image: busybox:1.36
        env:
        - {name: RUN_ID, value: "$T"}
        command:
        - sh
        - -c
        - |
          echo "ledger 2.3.1 starting (run \$RUN_ID)"
          if [ ! -f /state/booted ]; then
            touch /state/booted
            echo "loading configuration from /etc/ledger/ledger.conf"
            echo "connecting to database ledger-db:5432"
            echo "applying schema migrations"
            echo "FATAL migration $M failed: checksum mismatch (run \$RUN_ID)"
            sleep 2
            exit $X
          fi
          echo "previous start failed, skipping migrations (degraded mode)"
          echo "listening on :8080"
          exec sleep 360000
        volumeMounts: [{name: state, mountPath: /state}]
        resources: {requests: {cpu: 1m, memory: 4Mi}}
      volumes: [{name: state, emptyDir: {}}]
YAML
for i in $(seq 60); do
  [ "$(kubectl -n s04-crash get pod -l app=ledger -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}{.items[0].status.containerStatuses[0].ready}' 2>/dev/null)" = 1true ] && break; sleep 2
done
kubectl annotate ns s04-crash simulator/pod="$(kubectl -n s04-crash get pod -l app=ledger -o jsonpath='{.items[0].metadata.name}')" --overwrite >/dev/null
