D=/opt/course/s15-deploy
cat > $D/deploys.sh <<'SH'
kubectl get deploy -n s15-deploy -o custom-columns=DEPLOYMENT:.metadata.name,CONTAINER_IMAGE:.spec.template.spec.containers[0].image,READY_REPLICAS:.status.readyReplicas,NAMESPACE:.metadata.namespace --sort-by=.metadata.name
SH
bash $D/deploys.sh > $D/deploys.txt
kubectl -n s15-deploy get deploy --sort-by=.metadata.creationTimestamp -o custom-columns=:.metadata.name --no-headers > $D/by-age.txt
cat $D/*
