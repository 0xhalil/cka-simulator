course_dir s07-clusterrole
kubectl delete clusterrolebinding s07-storage-admin s07-infra-legacy --ignore-not-found >/dev/null
kubectl delete clusterrole s07-storage-admin s07-infra-legacy --ignore-not-found >/dev/null
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata: {name: s07-infra-legacy}
rules:
- apiGroups: [""]
  resources: [nodes, persistentvolumes, namespaces]
  verbs: ["*"]
- apiGroups: [storage.k8s.io]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata: {name: s07-infra-legacy}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: ClusterRole, name: s07-infra-legacy}
subjects:
- {apiGroup: rbac.authorization.k8s.io, kind: User, name: s07-bob}
- {apiGroup: rbac.authorization.k8s.io, kind: User, name: s07-alice}
- {apiGroup: rbac.authorization.k8s.io, kind: Group, name: s07-infra-oncall}
YAML
