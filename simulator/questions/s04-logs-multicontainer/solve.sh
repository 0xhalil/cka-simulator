D=/opt/course/s04-logs
kubectl -n s04-logs logs payment-gw -c audit-agent | grep ERROR > $D/audit-errors.log
kubectl -n s04-logs logs payment-gw -c gateway --tail=5 > $D/gateway-tail.log
kubectl -n s04-logs logs payment-gw -c audit-agent --timestamps | head -3 > $D/audit-ts.log
