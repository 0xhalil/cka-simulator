P="pod metrics-agent -n s05-resize"
guard "Pod metrics-agent was not recreated (same UID)" '[ "$(jp $P "{.metadata.uid}")" = "$(cat /root/.s05-resize-uid)" ]'
check "spec: CPU request 100m / limit 200m" '[ "$(jp $P "{.spec.containers[0].resources.requests.cpu}/{.spec.containers[0].resources.limits.cpu}")" = 100m/200m ]'
check "spec: memory request 32Mi / limit 128Mi" '[ "$(jp $P "{.spec.containers[0].resources.requests.memory}/{.spec.containers[0].resources.limits.memory}")" = 32Mi/128Mi ]'
check "kubelet applied the new resources (container status)" 'for i in $(seq 1 20); do [ "$(jp $P "{.status.containerStatuses[0].resources.limits.cpu}/{.status.containerStatuses[0].resources.limits.memory}")" = 200m/128Mi ] && exit 0; sleep 3; done; exit 1'
check "container restarted exactly once (only for the memory change)" '[ "$(jp $P "{.status.containerStatuses[0].restartCount}")" = 1 ]'
check "restarts.txt contains the restart count" '[ "$(tr -d " \n" < /opt/course/s05-resize/restarts.txt)" = "$(jp $P "{.status.containerStatuses[0].restartCount}")" ]'
