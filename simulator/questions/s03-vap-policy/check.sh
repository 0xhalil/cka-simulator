dep() {  # dep <ns> <replicas> -> server-side dry-run create output
  printf 'apiVersion: apps/v1\nkind: Deployment\nmetadata: {name: vap-chk, namespace: %s}\nspec:\n  replicas: %s\n  selector: {matchLabels: {app: vap-chk}}\n  template:\n    metadata: {labels: {app: vap-chk}}\n    spec: {containers: [{name: c, image: busybox:1.36}]}\n' "$1" "$2" \
    | kubectl create --dry-run=server -f - 2>&1
}
MSG='replicas must not exceed 5 in production'
check "ValidatingAdmissionPolicy vap-replica-cap exists with failurePolicy Fail" "[ \"\$(jp validatingadmissionpolicy vap-replica-cap '{.spec.failurePolicy}')\" = Fail ]"
check "creating a Deployment with 6 replicas in vap-prod is denied with the required message" "dep vap-prod 6 | grep -q \"\$MSG\""
check "updating a Deployment in vap-prod to 6 replicas is denied" "kubectl -n vap-prod patch deploy legacy-batch --dry-run=server -p '{\"spec\":{\"replicas\":6}}' 2>&1 | grep -q \"\$MSG\""
check "scaling (kubectl scale) to 7 replicas in vap-prod is denied" "kubectl -n vap-prod scale deploy legacy-batch --replicas=7 --dry-run=server 2>&1 | grep -q \"\$MSG\""
check "binding only applies to env=prod: 6 replicas allowed in vap-dev, 5 allowed in vap-prod (while 6 is denied in vap-prod)" "dep vap-prod 6 | grep -q \"\$MSG\" && dep vap-dev 6 | grep -q created && dep vap-prod 5 | grep -q created"
check "binding vap-replica-cap-binding uses validationAction Deny" "jp validatingadmissionpolicybinding vap-replica-cap-binding '{.spec.validationActions}' | grep -q Deny"
check "Deployment legacy-batch is set to 5 replicas" "[ \"\$(jp deploy legacy-batch -n vap-prod '{.spec.replicas}')\" = 5 ]"
