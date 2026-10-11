X() { kubectl -n s07-sec exec secure-app -c "$1" -- sh -c "$2" 2>/dev/null </dev/null; }
C() { jp pod secure-app -n s07-sec "{.spec.containers[?(@.name==\"$1\")].securityContext.$2}"; }
capbit() { X "$1" "grep $2 /proc/1/status" | awk '{print $2}'; }
kubectl -n s07-sec wait --for=condition=Ready pod/secure-app --timeout=60s >/dev/null 2>&1
check "Pod secure-app Running; container app runs as uid 1000, gid 3000, supplemental group 2000" '[ "$(X app "id -u"):$(X app "id -g")" = 1000:3000 ] && X app "id -G" | tr " " "\n" | grep -qx 2000'
check "volume files belong to group 2000 (fsGroup)" '[ "$(X app "stat -c %g /data")" = 2000 ]'
check "container app has a read-only root filesystem but can write /data" '[ "$(C app readOnlyRootFilesystem)" = true ] && ! X app "touch /s07-test" && X app "touch /data/s07-test"'
check "container app: allowPrivilegeEscalation false (NoNewPrivs)" '[ "$(C app allowPrivilegeEscalation)" = false ] && [ "$(capbit app NoNewPrivs)" = 1 ]'
check "container app has all capabilities dropped" '[ "$(capbit app CapBnd)" = 0000000000000000 ]'
check "container clock overrides the Pod default (uid 1000) and runs as root" '[ "$(jp pod secure-app -n s07-sec "{.spec.securityContext.runAsUser}")" = 1000 ] && [ "$(X app "id -u")" = 1000 ] && [ "$(X clock "id -u")" = 0 ]'
check "container clock has capability SYS_TIME" 'e=$(capbit clock CapEff); [ -n "$e" ] && [ $(( 0x$e & 0x2000000 )) -ne 0 ]'
check "manifest file contains the securityContext changes" 'grep -q fsGroup /opt/course/s07-sec/secure-app.yaml && grep -q SYS_TIME /opt/course/s07-sec/secure-app.yaml && grep -q readOnlyRootFilesystem /opt/course/s07-sec/secure-app.yaml'
check "id.txt contains the id output of container app" 'grep -q "uid=1000" /opt/course/s07-sec/id.txt && grep -q "gid=3000" /opt/course/s07-sec/id.txt && grep -q "2000" /opt/course/s07-sec/id.txt'
guard "container clock is not privileged" '[ "$(C clock privileged)" != true ]'
