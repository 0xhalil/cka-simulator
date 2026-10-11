D=/opt/course/s15-deploy
ws() { awk '{$1=$1};1' | grep -v '^$'; }
exp() { kubectl get deploy -n s15-deploy -o custom-columns=DEPLOYMENT:.metadata.name,CONTAINER_IMAGE:.spec.template.spec.containers[0].image,READY_REPLICAS:.status.readyReplicas,NAMESPACE:.metadata.namespace --sort-by=.metadata.name; }
check "deploys.txt contains the sorted custom-columns table" '[ -s $D/deploys.txt ] && diff <(ws < $D/deploys.txt) <(exp | ws)'
check "deploys.sh produces exactly that table" '[ -s $D/deploys.sh ] && grep -q kubectl $D/deploys.sh && diff <(timeout 30 bash $D/deploys.sh 2>&1 | ws) <(exp | ws)'
check "by-age.txt lists the Deployments oldest first" '[ -s $D/by-age.txt ] && diff <(ws < $D/by-age.txt | sed "s#^deployment.apps/##") <(kubectl -n s15-deploy get deploy --sort-by=.metadata.creationTimestamp -o jsonpath="{range .items[*]}{.metadata.name}{\"\n\"}{end}" | ws)'
