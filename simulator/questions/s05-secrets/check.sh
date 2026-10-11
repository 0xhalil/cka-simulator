PW=$(kubectl -n s05-secret get secret legacy-db -o jsonpath='{.data.password}' | base64 -d)
X() { kubectl -n s05-secret exec api-client -- "$@"; }
check "password.txt contains the decoded password" '[ "$(tr -d "\n" < /opt/course/s05-secret/password.txt)" = "$PW" ]'
check "Secret api-creds has API_USER=svc-api and API_KEY=k8s-7f3a9c21" '[ "$(kubectl -n s05-secret get secret api-creds -o jsonpath="{.data.API_USER}" | base64 -d)/$(kubectl -n s05-secret get secret api-creds -o jsonpath="{.data.API_KEY}" | base64 -d)" = svc-api/k8s-7f3a9c21 ]'
check "Pod api-client is running (busybox:1.36)" 'kubectl -n s05-secret wait --for=condition=Ready pod/api-client --timeout=60s && [ "$(jp pod api-client -n s05-secret "{.spec.containers[0].image}")" = busybox:1.36 ]'
check "env API_KEY comes from Secret api-creds" '[ "$(jp pod api-client -n s05-secret "{.spec.containers[0].env[?(@.name==\"API_KEY\")].valueFrom.secretKeyRef.name}")" = api-creds ] && X printenv API_KEY | grep -qx k8s-7f3a9c21'
check "/etc/db contains only db-pass with the password" '[ "$(X ls /etc/db)" = db-pass ] && [ "$(X cat /etc/db/db-pass)" = "$PW" ]'
check "/etc/db/db-pass has mode 0400" '[ "$(X stat -L -c %a /etc/db/db-pass)" = 400 ]'
