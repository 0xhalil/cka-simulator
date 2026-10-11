UID0=$(cat /root/.s03-manual-api.uid 2>/dev/null)
P="pod -n s03-manual"
check "Pod manual-web is Running on cka-w1" '[ "$(jp $P manual-web "{.spec.nodeName}/{.status.phase}")" = cka-w1/Running ]'
check "manual-web keeps image nginx:1.27-alpine, labels app=manual-web,tier=frontend and schedulerName s03-offline-scheduler" \
  '[ "$(jp $P manual-web "{.spec.nodeName}|{.spec.containers[0].image}|{.metadata.labels.app}|{.metadata.labels.tier}|{.spec.schedulerName}")" = "cka-w1|nginx:1.27-alpine|manual-web|frontend|s03-offline-scheduler" ]'
check "Pod manual-api is Running on cka-w1" 'for i in $(seq 1 20); do [ "$(jp $P manual-api "{.spec.nodeName}/{.status.phase}")" = cka-w1/Running ] && exit 0; sleep 2; done; exit 1'
check "manual-api was NOT deleted/recreated (same UID) and still uses schedulerName s03-offline-scheduler" \
  '[ -n "$UID0" ] && [ "$(jp $P manual-api "{.spec.nodeName}|{.metadata.uid}|{.spec.schedulerName}")" = "cka-w1|$UID0|s03-offline-scheduler" ]'
