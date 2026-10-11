```bash
ssh cka-cp1
k -n s05-recreate edit deploy ledger
#  strategy:
#    type: Recreate          # DELETE the rollingUpdate block, otherwise validation error
k -n s05-recreate set image deploy/ledger app=nginx:1.28-alpine      # only the "app" container
k -n s05-recreate annotate deploy ledger kubernetes.io/change-cause="upgrade app to 1.28" --overwrite
k -n s05-recreate rollout status deploy ledger
k -n s05-recreate rollout history deploy ledger
k -n s05-recreate get deploy ledger -o jsonpath='{.metadata.annotations.deployment\.kubernetes\.io/revision}' > /opt/course/s05-recreate/revision.txt
```
Traps:
- `type: Recreate` + `rollingUpdate:` can't coexist → the API rejects it.
- A strategy change alone doesn't create a new revision; only a Pod template change does.
- The change-cause annotation is copied from the Deployment to the newest ReplicaSet. Add it **after** the image change; if you add it before, the same text also shows up on the old revision and the history becomes misleading.
