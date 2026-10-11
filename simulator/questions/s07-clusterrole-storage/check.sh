ca() { kubectl auth can-i "$@" --as=s07-alice 2>/dev/null | grep -qx yes; }
D=/opt/course/s07-clusterrole
# does ClusterRole s07-storage-admin itself grant <group> <resource> <verbs...>?
cr() { kubectl get clusterrole s07-storage-admin -o json 2>/dev/null | python3 -c '
import json,sys
g,r,vs=sys.argv[1],sys.argv[2],sys.argv[3:]
rules=json.load(sys.stdin).get("rules") or []
m=lambda l,x: "*" in (l or []) or x in (l or [])
ok=all(any(m(ru.get("apiGroups"),g) and m(ru.get("resources"),r) and m(ru.get("verbs"),v) and not ru.get("resourceNames") for ru in rules) for v in vs)
sys.exit(0 if ok else 1)' "$@"; }
check "ClusterRole s07-storage-admin exists" 'kubectl get clusterrole s07-storage-admin'
check "ClusterRoleBinding s07-storage-admin binds User s07-alice to it" '[ "$(jp clusterrolebinding s07-storage-admin "{.roleRef.name} {.subjects[*].kind}/{.subjects[*].name}")" = "s07-storage-admin User/s07-alice" ]'
check "alice can get/list/watch nodes" 'cr "" nodes get list watch && ca get nodes && ca list nodes && ca watch nodes'
check "alice can manage persistentvolumes (get/list/watch/create/delete)" 'cr "" persistentvolumes get list watch create delete && for v in get list watch create delete; do ca $v persistentvolumes || exit 1; done'
check "alice can get/list/watch storageclasses" 'cr storage.k8s.io storageclasses get list watch && ca get storageclasses.storage.k8s.io && ca list storageclasses.storage.k8s.io && ca watch storageclasses.storage.k8s.io'
check "alice can no longer delete/patch nodes, update PVs or create storageclasses" '! ca delete nodes && ! ca patch nodes && ! ca update persistentvolumes && ! ca create storageclasses.storage.k8s.io && ! ca delete namespaces'
check "delete-nodes.txt says no, create-pv.txt says yes" '[ "$(tr -d "[:space:]" < $D/delete-nodes.txt)" = no ] && [ "$(tr -d "[:space:]" < $D/create-pv.txt)" = yes ]'
guard "ClusterRole s07-infra-legacy still exists unchanged" '[ "$(jp clusterrole s07-infra-legacy "{.rules[0].verbs[0]}")" = "*" ]'
guard "s07-bob and group s07-infra-oncall keep their permissions" 'kubectl auth can-i delete nodes --as=s07-bob | grep -qx yes && kubectl auth can-i delete nodes --as=x --as-group=s07-infra-oncall | grep -qx yes'
guard "alice has no namespaced permissions" '! ca list pods -A && ! ca list secrets -n default'
