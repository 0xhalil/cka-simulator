reset_ns s04-agg
course_dir s04-agg
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: worker, namespace: s04-agg}
spec:
  replicas: 3
  selector: {matchLabels: {app: worker, tier: batch}}
  template:
    metadata: {labels: {app: worker, tier: batch}}
    spec:
      terminationGracePeriodSeconds: 1
      containers:
      - name: job
        image: busybox:1.36
        command: ["sh", "-c", "n=$((RANDOM%6+13)); for i in $(seq 1 $n); do l=INFO; [ $((RANDOM%3)) = 0 ] && l=WARN; echo \"$l job=$RANDOM step=$i/$n\"; done; sleep 360000"]
        resources: {requests: {cpu: 1m, memory: 4Mi}}
      - name: uploader
        image: busybox:1.36
        command: ["sh", "-c", "for i in 1 2 3; do l=INFO; [ $((RANDOM%2)) = 0 ] && l=WARN; echo \"$l upload chunk=$RANDOM\"; done; sleep 360000"]
        resources: {requests: {cpu: 1m, memory: 4Mi}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: worker-legacy, namespace: s04-agg}
spec:
  replicas: 1
  selector: {matchLabels: {app: worker, tier: legacy}}
  template:
    metadata: {labels: {app: worker, tier: legacy}}
    spec:
      terminationGracePeriodSeconds: 1
      containers:
      - name: job
        image: busybox:1.36
        command: ["sh", "-c", "for i in 1 2 3 4; do echo \"WARN legacy job=$RANDOM deprecated\"; done; sleep 360000"]
        resources: {requests: {cpu: 1m, memory: 4Mi}}
YAML
wait_deploy s04-agg worker 120s; wait_deploy s04-agg worker-legacy 120s
sleep 3
true
