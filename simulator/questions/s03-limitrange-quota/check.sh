L="limitrange container-limits -n s03-quota"; Q="resourcequota team-quota -n s03-quota"
C='{.spec.limits[?(@.type=="Container")]'
mc() { case $1 in *m) echo ${1%m};; '') echo -1;; *) echo $(( $1 * 1000 ));; esac; }
mm() { case $1 in *Gi) echo $(( ${1%Gi} * 1024 ));; *Mi) echo ${1%Mi};; '') echo -1;; *) echo x;; esac; }
check "LimitRange container-limits: default limits cpu 200m / memory 128Mi" '[ "$(jp $L "$C.default.cpu}|$C.default.memory}")" = "200m|128Mi" ]'
check "LimitRange container-limits: default requests cpu 50m / memory 32Mi" '[ "$(jp $L "$C.defaultRequest.cpu}|$C.defaultRequest.memory}")" = "50m|32Mi" ]'
check "LimitRange container-limits: max cpu 500m / memory 256Mi" '[ "$(jp $L "$C.max.cpu}|$C.max.memory}")" = "500m|256Mi" ]'
check "ResourceQuota team-quota: requests.cpu 500m, requests.memory 512Mi" '[ "$(mc $(jp $Q "{.spec.hard.requests\.cpu}"))" = 500 ] && [ "$(mm $(jp $Q "{.spec.hard.requests\.memory}"))" = 512 ]'
check "ResourceQuota team-quota: limits.cpu 1, limits.memory 1Gi, pods 6" '[ "$(mc $(jp $Q "{.spec.hard.limits\.cpu}"))" = 1000 ] && [ "$(mm $(jp $Q "{.spec.hard.limits\.memory}"))" = 1024 ] && [ "$(jp $Q "{.spec.hard.pods}")" = 6 ]'
check "all 3 api Pods running with the LimitRange defaults (requests 50m/32Mi, limits 200m/128Mi)" '
  kubectl -n s03-quota rollout status deploy/api --timeout=30s || exit 1
  [ "$(jp deploy api -n s03-quota "{.status.readyReplicas}")" = 3 ] || exit 1
  for i in $(seq 1 15); do [ "$(kubectl -n s03-quota get pod -l app=api --field-selector status.phase=Running -o jsonpath="{range .items[*]}{.spec.containers[0].resources.requests.cpu}/{.spec.containers[0].resources.requests.memory}/{.spec.containers[0].resources.limits.cpu}/{.spec.containers[0].resources.limits.memory}{\"\n\"}{end}" | sort -u)" = "50m/32Mi/200m/128Mi" ] && exit 0; sleep 2; done; exit 1'
check "/opt/course/s03-quota/oversized.txt contains the LimitRange rejection message" 'grep -q "maximum cpu usage per Container is 500m" /opt/course/s03-quota/oversized.txt'
guard "Deployment api template has no explicit resources and Pod oversized does not exist" \
  '[ "$(jp deploy api -n s03-quota "{.spec.template.spec.containers[0].resources}")" = "{}" -o -z "$(jp deploy api -n s03-quota "{.spec.template.spec.containers[0].resources}")" ] && ! kubectl -n s03-quota get pod oversized'
