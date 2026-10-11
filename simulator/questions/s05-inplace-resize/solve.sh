kubectl -n s05-resize patch pod metrics-agent --subresource resize --patch '{"spec":{"containers":[{"name":"agent","resources":{"requests":{"cpu":"100m"},"limits":{"cpu":"200m"}}}]}}'
sleep 5
kubectl -n s05-resize patch pod metrics-agent --subresource resize --patch '{"spec":{"containers":[{"name":"agent","resources":{"limits":{"memory":"128Mi"}}}]}}'
for i in $(seq 1 40); do
  [ "$(kubectl -n s05-resize get pod metrics-agent -o jsonpath='{.status.containerStatuses[0].resources.limits.memory}')" = 128Mi ] && \
  [ "$(kubectl -n s05-resize get pod metrics-agent -o jsonpath='{.status.containerStatuses[0].ready}')" = true ] && break; sleep 3
done
kubectl -n s05-resize get pod metrics-agent -o jsonpath='{.status.containerStatuses[0].restartCount}' > /opt/course/s05-resize/restarts.txt
