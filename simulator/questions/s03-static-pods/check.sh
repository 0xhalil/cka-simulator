M=/etc/kubernetes/manifests
check "burner-source.txt names the node and manifest file of cpu-burner" '[ "$(tr -d "[:space:]" < /opt/course/s03-static/burner-source.txt)" = "cka-w1:$M/s03-healthcheck.yaml" ]'
check "cpu-burner is gone for good (manifest removed, no Pod in s03-static)" \
  '! on cka-w1 "grep -rqs cpu-burner $M" && for i in $(seq 1 25); do [ -z "$(kubectl -n s03-static get pod -o name | grep cpu-burner)" ] && exit 0; sleep 2; done; exit 1'
check "static Pod manifest $M/s03-static-web.yaml exists on cka-w1" 'on cka-w1 "test -f $M/s03-static-web.yaml"'
check "mirror Pod s03-static-web-cka-w1 is Running and Ready in namespace s03-static" \
  'for i in $(seq 1 20); do [ "$(jp pod s03-static-web-cka-w1 -n s03-static "{.status.phase}/{.status.containerStatuses[0].ready}")" = Running/true ] && exit 0; sleep 2; done; exit 1'
check "s03-static-web: image nginx:1.27-alpine, label app=static-web, requests cpu 10m / memory 16Mi" \
  '[ "$(jp pod s03-static-web-cka-w1 -n s03-static "{.spec.containers[0].image}|{.metadata.labels.app}|{.spec.containers[0].resources.requests.cpu}|{.spec.containers[0].resources.requests.memory}")" = "nginx:1.27-alpine|static-web|10m|16Mi" ]'
check "s03-static-web is a real static Pod (owned by the Node, not created via the API)" \
  '[ "$(jp pod s03-static-web-cka-w1 -n s03-static "{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}")" = Node/cka-w1 ]'
