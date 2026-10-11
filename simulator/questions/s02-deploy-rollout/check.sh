N="-n s02-deploy"
ready3() { for i in $(seq 40); do [ "$(jp $N deploy $1 '{.status.readyReplicas}/{.status.updatedReplicas}/{.status.replicas}')" = 3/3/3 ] && return 0; sleep 3; done; return 1; }
check "payment rolled back to the working template (nginx:1.27-alpine, no command override)" '[ "$(jp $N deploy payment "{.spec.template.spec.containers[0].image}|{.spec.template.spec.containers[0].command}")" = "nginx:1.27-alpine|" ]'
check "payment has 3 ready, up-to-date replicas" '[ "$(jp $N deploy payment "{.spec.replicas}")" = 3 ] && ready3 payment'
guard "payment was not deleted/recreated" '[ "$(jp $N deploy payment "{.metadata.uid}")" = "$(jp ns s02-deploy "{.metadata.annotations.simulator/payment-uid}")" ]'
check "checkout: 3 replicas, label app=checkout, container web" '[ "$(jp $N deploy checkout "{.spec.replicas}|{.spec.template.metadata.labels.app}|{.spec.template.spec.containers[*].name}")" = "3|checkout|web" ]'
check "checkout: RollingUpdate maxUnavailable 0, maxSurge 1, revisionHistoryLimit 5" '[ "$(jp $N deploy checkout "{.spec.strategy.type}|{.spec.strategy.rollingUpdate.maxUnavailable}|{.spec.strategy.rollingUpdate.maxSurge}|{.spec.revisionHistoryLimit}")" = "RollingUpdate|0|1|5" ]'
check "checkout runs httpd:2.4.68-alpine with 3 ready replicas" '[ "$(jp $N deploy checkout "{.spec.template.spec.containers[0].image}")" = httpd:2.4.68-alpine ] && ready3 checkout'
check "checkout rollout history keeps the previous revision with httpd:2.4-alpine" '
  uid=$(jp $N deploy checkout "{.metadata.uid}"); [ -n "$uid" ] || exit 1
  kubectl $N get rs -o jsonpath="{range .items[?(@.metadata.ownerReferences[0].uid==\"$uid\")]}{.spec.template.spec.containers[0].image}{\"\n\"}{end}" | grep -qx "httpd:2.4-alpine"'
