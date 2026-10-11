`custom-columns` runs per item, so the queries are written without `.items[*]`. `--sort-by` takes a JSONPath expression.

```bash
ssh cka-cp1
k -n s15-deploy get deploy -o json | less

k get deploy -n s15-deploy -o custom-columns=DEPLOYMENT:.metadata.name,CONTAINER_IMAGE:.spec.template.spec.containers[0].image,READY_REPLICAS:.status.readyReplicas,NAMESPACE:.metadata.namespace --sort-by=.metadata.name > /opt/course/s15-deploy/deploys.txt
# same command -> /opt/course/s15-deploy/deploys.sh

k -n s15-deploy get deploy --sort-by=.metadata.creationTimestamp -o custom-columns=:.metadata.name --no-headers > /opt/course/s15-deploy/by-age.txt
# or: -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
```
Traps: since `zeta-batch` is never ready, the `.status.readyReplicas` field is **absent** → custom-columns prints `<none>` (this is the correct output). The default order is by name but the creation order differs; for age, sort by `.metadata.creationTimestamp` (the AGE column of `get deploy` doesn't sort).
