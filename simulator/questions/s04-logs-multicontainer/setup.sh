reset_ns s04-logs
course_dir s04-logs
T=$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n')
cat <<YAML | kubectl apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata: {name: payment-gw, namespace: s04-logs, labels: {app: payment-gw}}
spec:
  terminationGracePeriodSeconds: 1
  containers:
  - name: gateway
    image: busybox:1.36
    env: [{name: T, value: "$T"}]
    command: ["sh", "-c", "for i in \$(seq 1 30); do l=INFO; [ \$((i%6)) = 0 ] && l=ERROR; echo \"\$l gateway request id=\$((i*7919%10007)) upstream=pay-\$((i%3)) trace=\$T-\$i\"; done; sleep 360000"]
    resources: {requests: {cpu: 1m, memory: 4Mi}}
  - name: audit-agent
    image: busybox:1.36
    env: [{name: T, value: "$T"}]
    command: ["sh", "-c", "for i in \$(seq 1 40); do l=INFO; [ \$((i%5)) = 0 ] && l=WARN; [ \$((i%7)) = 0 ] && l=ERROR; echo \"\$l audit event=\$i user=u\$((i*37%101)) token=\$T\"; sleep 0.2; done; sleep 360000"]
    resources: {requests: {cpu: 1m, memory: 4Mi}}
  - name: metrics
    image: busybox:1.36
    command: ["sh", "-c", "echo ERROR metrics exporter disabled; sleep 360000"]
    resources: {requests: {cpu: 1m, memory: 4Mi}}
YAML
kubectl -n s04-logs wait --for=condition=Ready pod/payment-gw --timeout=120s >/dev/null
sleep 10
true
