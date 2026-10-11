N="-n s02-rs"
owned() { kubectl $N get pod -o jsonpath='{range .items[?(@.metadata.ownerReferences[0].name=="backend")]}{.metadata.name}{" "}{.spec.containers[*].image}{" "}{.status.conditions[?(@.type=="Ready")].status}{" "}{.metadata.deletionTimestamp}{"\n"}{end}'; }
check "ReplicaSet backend keeps selector tier=backend and template image httpd:2.4-alpine" '[ "$(jp $N rs backend "{.spec.selector.matchLabels.tier}|{.spec.template.spec.containers[*].image}")" = "backend|httpd:2.4-alpine" ]'
check "ReplicaSet backend manages exactly 3 ready Pods, all with image httpd:2.4-alpine" '
  for i in $(seq 30); do o=$(owned | grep -v "^$"); n=$(echo "$o" | grep -c .); good=$(echo "$o" | awk "\$2==\"httpd:2.4-alpine\" && \$3==\"True\" && NF==3" | wc -l)
    [ "$n" = 3 ] && [ "$good" = 3 ] && exit 0; sleep 3; done; exit 1'
check "ReplicaSet frontend exists with selector app=frontend and 2 ready replicas" '
  [ "$(jp $N rs frontend "{.spec.selector.matchLabels.app}")" = frontend ] || exit 1
  for i in $(seq 30); do [ "$(jp $N rs frontend "{.status.readyReplicas}")" = 2 ] && exit 0; sleep 3; done; exit 1'
check "/opt/course/s02-rs/frontend-rs.yaml is fixed (valid on server, selector unchanged)" '
  F=/opt/course/s02-rs/frontend-rs.yaml; grep -qE "^apiVersion:[[:space:]]*apps/v1" $F && kubectl apply --dry-run=server -f $F && grep -q "app: frontend" $F'
