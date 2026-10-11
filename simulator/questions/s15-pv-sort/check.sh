D=/opt/course/s15-pv
ws() { awk '{$1=$1};1' | grep -v '^$'; }
check "pvs.txt lists NAME, CAPACITY, RECLAIM_POLICY sorted by capacity (ascending)" '[ -s $D/pvs.txt ] && diff <(ws < $D/pvs.txt) <(kubectl get pv -l report=s15 --sort-by=.spec.capacity.storage -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,RECLAIM_POLICY:.spec.persistentVolumeReclaimPolicy | ws)'
check "retain.txt contains exactly the Retain PVs" '[ -s $D/retain.txt ] && [ "$(grep -c . $D/retain.txt)" = 1 ] && [ "$(tr -s " \t" "\n\n" < $D/retain.txt | grep -v "^$" | sort | tr "\n" " ")" = "$(kubectl get pv -l report=s15 -o jsonpath="{.items[?(@.spec.persistentVolumeReclaimPolicy==\"Retain\")].metadata.name}" | tr " " "\n" | sort | tr "\n" " ")" ]'
check "largest.txt names the largest PV" '[ "$(tr -d "[:space:]" < $D/largest.txt | sed "s#^persistentvolume/##")" = "$(kubectl get pv -l report=s15 --sort-by=.spec.capacity.storage -o jsonpath="{.items[-1:].metadata.name}")" ]'
