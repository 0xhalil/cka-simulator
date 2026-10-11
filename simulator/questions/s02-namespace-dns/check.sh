N="-n s02-frontend"
check "fqdn.txt contains cache.s02-backend.svc.cluster.local" '[ "$(tr -d "[:space:]" < /opt/course/s02-dns/fqdn.txt | sed "s/\.$//")" = cache.s02-backend.svc.cluster.local ]'
check "webapp uses a DNS name of the cache Service in CACHE_HOST" 'jp $N deploy webapp "{.spec.template.spec.containers[0].env[?(@.name==\"CACHE_HOST\")].value}" | grep -Eqx "cache\.s02-backend(\.svc(\.cluster\.local\.?)?)?"'
check "ResourceQuota frontend-quota: pods=6, requests.cpu=500m, requests.memory=512Mi" '
  h=$(jp $N quota frontend-quota "{.spec.hard.pods}|{.spec.hard.requests\.cpu}{.spec.hard.cpu}|{.spec.hard.requests\.memory}{.spec.hard.memory}"); [ "$h" = "6|500m|512Mi" ]'
check "webapp has 2 ready, up-to-date replicas with the fixed configuration" '
  for i in $(seq 20); do [ "$(jp $N deploy webapp "{.status.readyReplicas}/{.status.updatedReplicas}/{.status.replicas}")" = 2/2/2 ] && [ "$(jp $N deploy webapp "{.status.observedGeneration}")" = "$(jp $N deploy webapp "{.metadata.generation}")" ] && \
    jp $N deploy webapp "{.spec.template.spec.containers[0].env[?(@.name==\"CACHE_HOST\")].value}" | grep -q "s02-backend" && exit 0; sleep 3; done; exit 1'
guard "Service cache in s02-backend unchanged" '[ "$(jp -n s02-backend svc cache "{.spec.selector.app}:{.spec.ports[0].port}")" = redis:6379 ]'
