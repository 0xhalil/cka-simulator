D="deploy ssd-cache -n s03-affinity"
A='{.spec.template.spec.affinity.nodeAffinity'
check "node cka-w1 is labeled s03.cka.local/disktype=ssd" '[ "$(jp node cka-w1 "{.metadata.labels.s03\.cka\.local/disktype}")" = ssd ]'
check "ssd-cache has no nodeSelector anymore" 'kubectl get $D && [ -z "$(jp $D "{.spec.template.spec.nodeSelector}")" ]'
check "required node affinity: s03.cka.local/disktype In [ssd, nvme]" \
  'kubectl get $D -o json | jq -e ".spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms | length == 1 and (.[0].matchExpressions | any(.key==\"s03.cka.local/disktype\" and .operator==\"In\" and ((.values|sort)==[\"nvme\",\"ssd\"])))"'
check "preferred node affinity: weight 75 for s03.cka.local/zone=zone-a" \
  'kubectl get $D -o json | jq -e ".spec.template.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution | any(.weight==75 and (.preference.matchExpressions | any(.key==\"s03.cka.local/zone\" and .operator==\"In\" and .values==[\"zone-a\"])))"'
check "2 ssd-cache replicas ready on cka-w1" \
  'kubectl -n s03-affinity rollout status deploy/ssd-cache --timeout=45s && [ "$(kubectl -n s03-affinity get pod -l app=ssd-cache --field-selector status.phase=Running -o jsonpath="{range .items[*]}{.spec.nodeName}{\"\n\"}{end}" | grep -c cka-w1)" = 2 ] && [ "$(jp $D "{.status.readyReplicas}")" = 2 ]'
guard "cka-cp1 not labeled with the disktype key and no node taints changed" \
  '[ -z "$(jp node cka-cp1 "{.metadata.labels.s03\.cka\.local/disktype}")" ] && [ -z "$(jp node cka-w1 "{.spec.taints}")" ] && jp node cka-cp1 "{.spec.taints[*].key}" | grep -q node-role.kubernetes.io/control-plane'
