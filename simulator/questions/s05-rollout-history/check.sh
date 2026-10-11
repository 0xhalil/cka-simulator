D="deploy web -n s05-rollout"; UID0=$(cat /root/.s05-rollout-web.uid 2>/dev/null)
check "broken-revision.txt contains the revision of the broken release" '[ "$(tr -d "[:space:]" < /opt/course/s05-rollout/broken-revision.txt)" = 4 ]'
check "Deployment web runs the v2-stable release (APP_VERSION=2, image nginx:1.27-alpine)" \
  '[ "$(jp $D "{.spec.template.spec.containers[0].image}|{.spec.template.spec.containers[0].env[?(@.name==\"APP_VERSION\")].value}")" = "nginx:1.27-alpine|2" ]'
check "web was rolled back (not recreated): same Deployment, new revision >= 5, change-cause release v2-stable" \
  '[ "$(jp $D "{.metadata.uid}|{.metadata.annotations.kubernetes\.io/change-cause}")" = "$UID0|release v2-stable" ] && [ "$(jp $D "{.metadata.annotations.deployment\.kubernetes\.io/revision}")" -ge 5 ]'
check "rolling update strategy: maxSurge 1, maxUnavailable 0" '[ "$(jp $D "{.spec.strategy.type}|{.spec.strategy.rollingUpdate.maxSurge}|{.spec.strategy.rollingUpdate.maxUnavailable}")" = "RollingUpdate|1|0" ]'
check "revisionHistoryLimit is 5" '[ "$(jp $D "{.spec.revisionHistoryLimit}")" = 5 ]'
check "all 4 replicas updated and ready, no Pods of other revisions left" \
  'kubectl -n s05-rollout rollout status deploy/web --timeout=30s && [ "$(jp $D "{.status.replicas}/{.status.updatedReplicas}/{.status.readyReplicas}")" = 4/4/4 ] && [ "$(kubectl -n s05-rollout get pod -l app=web --no-headers | grep -vc Terminating)" = 4 ]'
