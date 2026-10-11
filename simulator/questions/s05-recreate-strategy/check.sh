D="deploy ledger -n s05-recreate"
check "strategy is Recreate (no rollingUpdate settings left)" '[ "$(jp $D "{.spec.strategy.type}")" = Recreate ] && [ -z "$(jp $D "{.spec.strategy.rollingUpdate}")" ]'
check "container app uses nginx:1.28-alpine" '[ "$(jp $D "{.spec.template.spec.containers[?(@.name==\"app\")].image}")" = nginx:1.28-alpine ]'
check "rollout of the new version finished: 3 updated, ready replicas" '[ "$(jp $D "{.spec.template.spec.containers[?(@.name==\"app\")].image}")" = nginx:1.28-alpine ] && kubectl -n s05-recreate rollout status deploy/ledger --timeout=120s && [ "$(jp $D "{.status.updatedReplicas}/{.status.readyReplicas}")" = 3/3 ]'
check "current revision has change-cause 'upgrade app to 1.28'" 'R=$(jp $D "{.metadata.annotations.deployment\.kubernetes\.io/revision}"); kubectl -n s05-recreate rollout history deploy/ledger --revision=$R | grep -q "upgrade app to 1.28"'
check "revision.txt contains the current revision" '[ "$(tr -d " \n" < /opt/course/s05-recreate/revision.txt)" = "$(jp $D "{.metadata.annotations.deployment\.kubernetes\.io/revision}")" ]'
guard "log-agent image unchanged and Deployment not recreated" '[ "$(jp $D "{.spec.template.spec.containers[?(@.name==\"log-agent\")].image}")" = busybox:1.36 ] && [ "$(jp $D "{.metadata.uid}")" = "$(cat /root/.s05-recreate-uid)" ]'
