D=/opt/course/s04-top
# the expected answers are derived from what the pods do (deterministic), not from fluctuating numbers
who() { kubectl -n s04-top get pod -o jsonpath="{range .items[*]}{.metadata.name}{\" \"}{.spec.containers[0].command[2]}{\"\n\"}{end}" | grep -- "$1" | awk '{print $1}'; }
ans() { tr -d '[:space:]' < $1 2>/dev/null | sed 's#^pod/##'; }
runsh() { timeout 30 bash $1 2>&1; }
check "cpu.txt names the Pod with the highest CPU usage" '[ -n "$(who "while true")" ] && [ "$(ans $D/cpu.txt)" = "$(who "while true")" ]'
check "mem.txt names the Pod with the highest memory usage" '[ -n "$(who "dd if")" ] && [ "$(ans $D/mem.txt)" = "$(who "dd if")" ]'
check "nodes.sh shows node usage sorted by memory" '
  grep -Eq "top[[:space:]]+(node|nodes|no)\b" $D/nodes.sh && grep -Eq -- "--sort-by[= ]+memory" $D/nodes.sh && \
  o=$(runsh $D/nodes.sh) && echo "$o" | head -1 | grep -q "MEMORY" && echo "$o" | grep -q cka-cp1 && echo "$o" | grep -q cka-w1'
check "containers.sh shows per-container usage in s04-top" '
  grep -q -- "--containers" $D/containers.sh && o=$(runsh $D/containers.sh) && echo "$o" | head -1 | grep -Eq "^POD[[:space:]]+NAME" && \
  echo "$o" | grep -q "[[:space:]]worker[[:space:]]" && echo "$o" | grep -q "[[:space:]]proxy[[:space:]]" && echo "$o" | grep -q "^analytics-"'
