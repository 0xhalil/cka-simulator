D=/opt/course/s04-agg
kubectl -n s04-agg get deploy worker -o jsonpath='{.spec.selector.matchLabels}'; echo
kubectl -n s04-agg logs -l app=worker,tier=batch --all-containers --prefix --tail=-1 > $D/worker.log
grep -c WARN $D/worker.log > $D/warn-count.txt
cat $D/worker.log $D/warn-count.txt
