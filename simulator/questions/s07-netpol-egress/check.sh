# probe <ns> <labels> <host> <port> -> 0 if TCP connect succeeds
probe() {
  local n="s07probe-$RANDOM"
  kubectl -n "$1" run "$n" --image=busybox:1.36 --labels="$2" --restart=Never --command -- sh -c "nc -z -w 3 $3 $4" >/dev/null 2>&1
  kubectl -n "$1" wait --for=jsonpath='{.status.phase}'=Succeeded pod/"$n" --timeout=30s >/dev/null 2>&1; local rc=$?
  kubectl -n "$1" delete pod "$n" --now >/dev/null 2>&1; return $rc
}
fromapi() { kubectl -n s07-np-app exec deploy/api -- sh -c "$1" >/dev/null 2>&1 </dev/null; }
A=api.s07-np-app.svc.cluster.local
has() { kubectl -n s07-np-app get netpol "$1" >/dev/null 2>&1; }
check "NetworkPolicy default-deny-ingress selects all Pods with policyType Ingress" '[ "$(jp netpol default-deny-ingress -n s07-np-app "{.spec.podSelector}")" = "{}" ] && jp netpol default-deny-ingress -n s07-np-app "{.spec.policyTypes}" | grep -q Ingress && [ -z "$(jp netpol default-deny-ingress -n s07-np-app "{.spec.ingress}")" ]'
check "frontend Pods (s07-np-web) can reach api on port 80" 'has api-policy && kubectl -n s07-np-web exec deploy/frontend -- wget -qO- -T 4 http://$A >/dev/null'
check "other Pods in s07-np-web cannot reach api" 'has api-policy && ! probe s07-np-web role=other $A 80'
check "Pods labeled role=frontend in other namespaces cannot reach api" 'has api-policy && ! probe s07-np-app role=frontend $A 80'
check "api can resolve DNS and reach db:6379" 'has api-policy && fromapi "nslookup db.s07-np-app.svc.cluster.local && nc -z -w 3 db.s07-np-app.svc.cluster.local 6379"'
check "api cannot reach cache:6379 or the Kubernetes API" 'has api-policy && fromapi "nslookup cache.s07-np-app.svc.cluster.local" && ! fromapi "nc -z -w 3 cache.s07-np-app.svc.cluster.local 6379" && ! fromapi "nc -z -w 3 kubernetes.default.svc.cluster.local 443"'
check "db is not reachable from cache (only api allowed)" 'has db-policy && ! kubectl -n s07-np-app exec deploy/cache -- nc -z -w 3 db.s07-np-app.svc.cluster.local 6379 </dev/null'
check "cache is not reachable from other Pods (default deny)" 'has default-deny-ingress && ! probe s07-np-app app=probe cache.s07-np-app.svc.cluster.local 6379'
guard "Deployments unchanged and available" 'for d in api db cache; do kubectl -n s07-np-app rollout status deploy/$d --timeout=20s || exit 1; done; [ "$(jp deploy api -n s07-np-app "{.spec.template.metadata.labels.app}")" = api ]'
