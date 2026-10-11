D=/opt/course/s04-crash
P=$(jp ns s04-crash '{.metadata.annotations.simulator/pod}')
spec=$(jp -n s04-crash deploy ledger '{.spec.template.spec.containers[0].command[2]}')
M=$(echo "$spec" | grep -o 'FATAL migration [0-9]*' | awk '{print $3}')
X=$(echo "$spec" | grep -o 'exit [0-9]*' | awk '{print $2}')
check "crash.log contains exactly the logs of the crashed (previous) container instance" '
  [ -s $D/crash.log ] && ! grep -q "listening on" $D/crash.log && grep -q "FATAL migration" $D/crash.log || exit 1
  prev=$(kubectl -n s04-crash logs $P -c ledger --previous 2>/dev/null)
  if [ -n "$prev" ]; then diff <(sed "s/[[:space:]]*$//" $D/crash.log | grep -v "^$") <(echo "$prev" | sed "s/[[:space:]]*$//" | grep -v "^$"); else grep -c . $D/crash.log | grep -qx 5; fi'
check "exit-code.txt contains the exit code of the crashed instance" '[ -n "$X" ] && [ "$(tr -d "[:space:]" < $D/exit-code.txt)" = "$X" ]'
check "migration.txt contains the failed migration number" '[ -n "$M" ] && [ "$(tr -d "[:space:]" < $D/migration.txt)" = "$M" ]'
guard "Pod was not deleted/restarted (same Pod, restartCount 1)" '[ -n "$P" ] && [ "$(jp -n s04-crash pod $P "{.status.containerStatuses[0].restartCount}")" = 1 ]'
