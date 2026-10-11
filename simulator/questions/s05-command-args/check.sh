cmd1() { kubectl -n s05-cmd exec "$1" -c "$2" -- cat /proc/1/cmdline 2>/dev/null | tr '\0' ' '; }
check "Deployment sleeper is available and its container runs 'sleep 3600'" '
  kubectl -n s05-cmd rollout status deploy/sleeper --timeout=30s && [ "$(jp deploy sleeper -n s05-cmd "{.status.readyReplicas}")" = 1 ] || exit 1
  for i in $(seq 1 10); do p=$(kubectl -n s05-cmd get pod -l app=sleeper --field-selector status.phase=Running -o name | head -1); [ -n "$p" ] && [ "$(cmd1 $p sleeper)" = "sleep 3600 " ] && exit 0; sleep 2; done; exit 1'
guard "sleeper still uses image busybox:1.36" '[ "$(jp deploy sleeper -n s05-cmd "{.spec.template.spec.containers[0].image}")" = busybox:1.36 ]'
check "Pod cache (redis:7-alpine) is Running" 'for i in $(seq 1 30); do [ "$(jp pod cache -n s05-cmd "{.spec.containers[0].image}/{.status.phase}")" = redis:7-alpine/Running ] && exit 0; sleep 2; done; exit 1'
check "cache does not override the image ENTRYPOINT (no command set)" 'kubectl -n s05-cmd get pod cache && [ -z "$(jp pod cache -n s05-cmd "{.spec.containers[0].command}")" ]'
check "redis listens on port 6380 with maxmemory 32mb" \
  '[ "$(kubectl -n s05-cmd exec cache -- redis-cli -p 6380 config get maxmemory | tail -1)" = 33554432 ]'
check "redis-server runs as user redis (entrypoint dropped privileges)" \
  '[ "$(kubectl -n s05-cmd exec cache -- stat -c %U /proc/1)" = redis ] && kubectl -n s05-cmd exec cache -- cat /proc/1/cmdline | tr "\0" " " | grep -q "^redis-server"'
