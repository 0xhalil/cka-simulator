D=/opt/course/s04-crash
P=$(kubectl -n s04-crash get pod -l app=ledger -o jsonpath='{.items[0].metadata.name}')
kubectl -n s04-crash logs $P --previous > $D/crash.log
kubectl -n s04-crash get pod $P -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}' > $D/exit-code.txt
grep -o 'FATAL migration [0-9]*' $D/crash.log | awk '{print $3}' > $D/migration.txt
cat $D/*
