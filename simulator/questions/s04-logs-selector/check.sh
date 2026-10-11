D=/opt/course/s04-agg; N="-n s04-agg"
pods() { kubectl $N get pod -l app=worker,tier=batch -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'; }
all() { for p in $(pods); do for c in job uploader; do kubectl $N logs $p -c $c; done; done; }
check "worker.log contains every log line of every worker container, prefixed with its Pod name" '
  [ -s $D/worker.log ] && [ -n "$(pods)" ] || exit 1
  for p in $(pods); do for c in job uploader; do kubectl $N logs $p -c $c | while read -r line; do grep -F -- "$line" $D/worker.log | grep -qF "$p" || exit 1; done || exit 1; done; done'
check "worker.log contains no lines from other Pods (worker-legacy)" '[ -s $D/worker.log ] && ! grep -q "legacy" $D/worker.log && [ "$(grep -c . $D/worker.log)" = "$(all | grep -c .)" ]'
check "warn-count.txt has the total number of WARN lines" '[ -n "$(pods)" ] && [ "$(tr -d "[:space:]" < $D/warn-count.txt)" = "$(all | grep -c WARN)" ]'
