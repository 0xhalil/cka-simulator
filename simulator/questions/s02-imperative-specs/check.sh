N="-n s02-imp"; F=/opt/course/s02-imp/worker.yaml
check "Pod nginx-prod (nginx:1.27-alpine) with labels tier=web,env=prod is running" '[ "$(jp $N pod nginx-prod "{.spec.containers[0].image}|{.metadata.labels.tier}|{.metadata.labels.env}")" = "nginx:1.27-alpine|web|prod" ] && kubectl $N wait --for=condition=Ready pod/nginx-prod --timeout=60s'
check "Pod httpd-edge (httpd:2.4-alpine) declares containerPort 80" '[ "$(jp $N pod httpd-edge "{.spec.containers[0].image}|{.spec.containers[0].ports[*].containerPort}")" = "httpd:2.4-alpine|80" ]'
check "Service httpd-edge (ClusterIP, port 8080) answers with the httpd Pod" '
  [ "$(jp $N svc httpd-edge "{.spec.type}|{.spec.ports[0].port}")" = "ClusterIP|8080" ] || exit 1
  ip=$(jp $N svc httpd-edge "{.spec.clusterIP}"); for i in $(seq 10); do curl -s --max-time 3 http://$ip:8080/ | grep -q "It works" && exit 0; sleep 3; done; exit 1'
check "Deployment cache (redis:7-alpine) in s02-imp-dev has 2 ready replicas" '
  [ "$(jp -n s02-imp-dev deploy cache "{.spec.template.spec.containers[0].image}")" = redis:7-alpine ] || exit 1
  for i in $(seq 20); do [ "$(jp -n s02-imp-dev deploy cache "{.status.readyReplicas}")" = 2 ] && exit 0; sleep 3; done; exit 1'
check "worker.yaml is a valid Deployment manifest (worker, busybox:1.36, 3 replicas, sleep 3600)" '
  o=$(kubectl create --dry-run=client -f $F -o jsonpath="{.kind}|{.metadata.name}|{.spec.replicas}|{.spec.template.spec.containers[0].image}|{.spec.template.spec.containers[0].command} {.spec.template.spec.containers[0].args}") || exit 1
  echo "$o" | grep -q "^Deployment|worker|3|busybox:1.36|" && echo "$o" | grep -q "sleep" && echo "$o" | grep -q "3600" && \
  ns=$(kubectl create --dry-run=client -f $F -o jsonpath="{.metadata.namespace}") && { [ -z "$ns" ] || [ "$ns" = s02-imp ]; }'
check "Deployment worker was NOT created in the cluster" '[ -s $F ] && ! kubectl $N get deploy worker'
