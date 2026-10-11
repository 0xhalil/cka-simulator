P() { kubectl -n s05-config get pod -l app=webapp --field-selector status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null; }
X() { kubectl -n s05-config exec "$(P)" -c nginx -- "$@"; }
check "ConfigMap webapp-config has APP_COLOR=blue and APP_MODE=prod" '[ "$(jp cm webapp-config -n s05-config "{.data.APP_COLOR}/{.data.APP_MODE}")" = blue/prod ]'
check "ConfigMap key extra.conf has the content of /opt/course/s05-config/extra.conf" 'diff <(kubectl -n s05-config get cm webapp-config -o jsonpath="{.data.extra\.conf}") /opt/course/s05-config/extra.conf'
guard "Deployment webapp rolled out with all replicas ready" 'kubectl -n s05-config rollout status deploy/webapp --timeout=90s && [ "$(jp deploy webapp -n s05-config "{.status.readyReplicas}")" = "$(jp deploy webapp -n s05-config "{.spec.replicas}")" ]'
check "container has APP_COLOR=blue and APP_MODE=prod" 'X printenv APP_COLOR | grep -qx blue && X printenv APP_MODE | grep -qx prod'
check "COLOR env var comes from ConfigMap key APP_COLOR" '[ "$(jp deploy webapp -n s05-config "{.spec.template.spec.containers[0].env[?(@.name==\"COLOR\")].valueFrom.configMapKeyRef.name}/{.spec.template.spec.containers[0].env[?(@.name==\"COLOR\")].valueFrom.configMapKeyRef.key}")" = webapp-config/APP_COLOR ] && X printenv COLOR | grep -qx blue'
check "/etc/nginx/conf.d/extra.conf mounted and default.conf still present" 'X test -f /etc/nginx/conf.d/extra.conf && X test -f /etc/nginx/conf.d/default.conf'
check "nginx answers on :8080/healthz" 'X wget -qO- http://127.0.0.1:8080/healthz | grep -q webapp-healthy'
