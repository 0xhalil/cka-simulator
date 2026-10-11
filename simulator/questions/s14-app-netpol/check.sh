W=s14-pay-web; A=s14-pay-api
probe() {  # probe <ns> <labels> -> 0 if payments pod reachable directly on its pod IP port 80
  local n="probe-$RANDOM" ip; ip=$(kubectl -n $A get po -l app=payments -o jsonpath='{.items[0].status.podIP}')
  kubectl -n "$1" run "$n" --image=busybox:1.36 --labels="$2" --restart=Never --command -- sh -c "for i in 1 2 3; do wget -qO- -T 3 http://$ip:80/ | grep -q PAYMENT-OK && exit 0; sleep 2; done; exit 1" >/dev/null 2>&1
  kubectl -n "$1" wait --for=jsonpath='{.status.phase}'=Succeeded pod/"$n" --timeout=40s >/dev/null 2>&1; local rc=$?
  kubectl -n "$1" delete pod "$n" --now >/dev/null 2>&1; return $rc
}
cpod() { kubectl -n $W get po -l app=checkout --field-selector=status.phase=Running --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1:].metadata.name}'; }
check "PAYMENTS_URL used by checkout resolves in DNS from the checkout Pod" 'H=$(kubectl -n $W exec "$(cpod)" -- sh -c "echo \$PAYMENTS_URL" | sed -E "s#^[a-z]+://##; s#[:/].*##"); kubectl -n $W exec "$(cpod)" -- ping -c1 -W1 "$H" 2>&1 | grep -q "^PING .*([0-9.]*)"'
check "a checkout Pod can reach the payments Pods on their container port (egress + ingress allowed)" 'probe $W app=checkout'
check "checkout Pod receives PAYMENT-OK through PAYMENTS_URL" 'for i in 1 2 3 4 5; do kubectl -n $W exec "$(cpod)" -- sh -c "wget -qO- -T 3 \$PAYMENTS_URL" | grep -q PAYMENT-OK && exit 0; sleep 3; done; exit 1'
check "Deployment checkout is Ready (1/1)" 'kubectl -n $W wait --for=condition=available deploy/checkout --timeout=60s && [ "$(jp deploy checkout -n $W "{.status.readyReplicas}")" = 1 ]'
guard "existing NetworkPolicies unchanged (not deleted/recreated/edited)" '[ "$(kubectl get netpol -n $A default-deny-ingress allow-checkout -o jsonpath="{range .items[*]}{.metadata.uid}{end}")$(kubectl get netpol -n $W default-deny-egress allow-dns -o jsonpath="{range .items[*]}{.metadata.uid}{end}")" = "$(cat /root/.s14/netpol.uid)" ] && [ "$(kubectl get netpol -n $A default-deny-ingress allow-checkout -o jsonpath="{range .items[*]}{.metadata.generation}{end}")$(kubectl get netpol -n $W default-deny-egress allow-dns -o jsonpath="{range .items[*]}{.metadata.generation}{end}")" = 1111 ]'
guard "payments Deployment and Service unchanged" '[ "$(kubectl -n $A get deploy/payments svc/payments -o jsonpath="{range .items[*]}{.metadata.generation}{.spec.ports}{end}")" = "$(cat /root/.s14/netpol.api)" ]'
guard "other Pods in s14-pay-web cannot reach payments" '! probe $W app=other'
guard "Pods labeled app=checkout in other namespaces cannot reach payments" '! probe $A app=checkout'
