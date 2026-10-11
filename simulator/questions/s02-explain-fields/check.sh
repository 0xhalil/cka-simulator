N="-n s02-explain"; F=/opt/course/s02-explain/fields.txt
P="pod toolbox"
val() { grep -E "^[[:space:]]*$1[[:space:]]*=" $F 2>/dev/null | head -1 | cut -d= -f2- | tr -d "[:space:]" | sed -E "s/^\.//; s/^deployment\.//I"; }
check "Pod toolbox runs container shell (busybox:1.36, sleep 3600) and is ready" '[ "$(jp $N $P "{.spec.containers[0].name}|{.spec.containers[0].image}")" = "shell|busybox:1.36" ] && jp $N $P "{.spec.containers[0].command} {.spec.containers[0].args}" | grep -q 3600 && kubectl $N wait --for=condition=Ready pod/toolbox --timeout=60s'
check "shareProcessNamespace is enabled (container sees the pause process)" '[ "$(jp $N $P "{.spec.shareProcessNamespace}")" = true ] && kubectl $N exec toolbox -c shell -- ps | grep -q pause'
check "Service links are disabled (enableServiceLinks: false)" '[ "$(jp $N $P "{.spec.enableServiceLinks}")" = false ]'
check "terminationGracePeriodSeconds is 5" '[ "$(jp $N $P "{.spec.terminationGracePeriodSeconds}")" = 5 ]'
check "/etc/hosts maps legacy-db and legacy-db.internal to 10.10.10.10 (hostAliases)" '
  [ "$(jp $N $P "{.spec.hostAliases[?(@.ip==\"10.10.10.10\")].hostnames}" | tr -d "[]\" " | tr , "\n" | sort | tr "\n" " ")" = "legacy-db legacy-db.internal " ] && \
  kubectl $N exec toolbox -c shell -- grep -E "^10\.10\.10\.10[[:space:]]" /etc/hosts | grep -q legacy-db.internal'
check "HISTORY=spec.revisionHistoryLimit" '[ "$(val HISTORY)" = spec.revisionHistoryLimit ]'
check "READY=spec.minReadySeconds" '[ "$(val READY)" = spec.minReadySeconds ]'
check "DEADLINE=spec.progressDeadlineSeconds" '[ "$(val DEADLINE)" = spec.progressDeadlineSeconds ]'
