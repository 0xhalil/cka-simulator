probe() {  # probe <ns> <labels> -> 0 if backend reachable
  local n="probe-$RANDOM"
  kubectl -n "$1" run "$n" --image=busybox:1.36 --labels="$2" --restart=Never --command -- sh -c 'wget -qO- -T 4 http://backend-svc.backend.svc.cluster.local >/dev/null' >/dev/null 2>&1
  kubectl -n "$1" wait --for=jsonpath='{.status.phase}'=Succeeded pod/"$n" --timeout=40s >/dev/null 2>&1; local rc=$?
  kubectl -n "$1" delete pod "$n" --now >/dev/null 2>&1; return $rc
}
guard "default-deny-ingress still present and unchanged" "[ \"\$(jp netpol default-deny-ingress -n backend '{.spec.podSelector}')\" = '{}' ]"
check "netpol-2 (allow-frontend-pods) applied" "kubectl -n backend get netpol allow-frontend-pods"
check "netpol-1 and netpol-3 not applied, no extra policies" "[ \"\$(kubectl -n backend get netpol --no-headers | wc -l)\" -eq 2 ]"
check "frontend Pod can reach backend-svc" "kubectl -n frontend exec deploy/frontend -- wget -qO- -T 4 http://backend-svc.backend.svc.cluster.local"
guard "other Pod in namespace frontend is blocked" "! probe frontend app=other"
guard "Pod labeled app=frontend in another namespace is blocked" "! probe netpol-test app=frontend"
