N=s14-relay; U=$(cat /root/.s14/endpoints.uid 2>/dev/null)
probe() {  # probe <url> <expect>
  local n="probe-$RANDOM"
  kubectl -n default run "$n" --image=busybox:1.36 --restart=Never --labels=s14-probe=relay --command -- \
    sh -c "for i in 1 2 3 4; do wget -qO- -T 4 '$1' 2>/dev/null | grep -q '$2' && exit 0; sleep 2; done; exit 1" >/dev/null 2>&1
  kubectl -n default wait --for=jsonpath='{.status.phase}'=Succeeded pod/"$n" --timeout=45s >/dev/null 2>&1; local rc=$?
  kubectl -n default delete pod "$n" --now >/dev/null 2>&1; return $rc
}
check "all 3 relay Pods are Ready" 'kubectl -n $N wait --for=condition=available deploy/relay --timeout=30s && [ "$(jp deploy relay -n $N "{.status.readyReplicas}")" = 3 ]'
check "Service relay-svc has 3 ready endpoints" 'for i in 1 2 3 4 5; do [ "$(kubectl -n $N get endpointslice -l kubernetes.io/service-name=relay-svc -o jsonpath="{range .items[*].endpoints[*]}{.conditions.ready}{\"\n\"}{end}" | grep -c true)" = 3 ] && exit 0; sleep 2; done; exit 1'
check "endpoints of relay-svc are the relay Pods on port 80" '[ "$(kubectl -n $N get endpointslice -l kubernetes.io/service-name=relay-svc -o jsonpath="{.items[*].ports[*].port}")" = 80 ] && [ "$(kubectl -n $N get endpointslice -l kubernetes.io/service-name=relay-svc -o jsonpath="{range .items[*].endpoints[*]}{.targetRef.name}{\"\n\"}{end}" | sort)" = "$(kubectl -n $N get po -l app=relay -o jsonpath="{range .items[*]}{.metadata.name}{\"\n\"}{end}" | sort)" ]'
check "http://relay-svc.s14-relay returns the httpd page from another namespace" 'probe http://relay-svc.s14-relay "It works!"'
guard "readiness probe still configured on container relay" '[ -n "$(jp deploy relay -n $N "{.spec.template.spec.containers[0].readinessProbe.httpGet}{.spec.template.spec.containers[0].readinessProbe.tcpSocket}{.spec.template.spec.containers[0].readinessProbe.exec}")" ]'
guard "Deployment and Service not deleted/recreated" '[ "$(kubectl -n $N get deploy/relay svc/relay-svc -o jsonpath="{.items[*].metadata.uid}")" = "$U" ]'
