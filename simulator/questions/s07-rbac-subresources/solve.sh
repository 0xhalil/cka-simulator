cat <<'YAML' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: support, namespace: s07-apps}
rules:
- apiGroups: [""]
  resources: [pods]
  verbs: [get, list]
- apiGroups: [""]
  resources: [pods/log]
  verbs: [get]
- apiGroups: [""]
  resources: [pods/exec]
  resourceNames: [debug-shell]
  verbs: [create, get]
- apiGroups: [""]
  resources: [configmaps]
  resourceNames: [app-config]
  verbs: [get, update, patch]
YAML
kubectl -n s07-apps create rolebinding support --role=support --group=s07-support
kubectl -n s07-apps logs app --as=tom --as-group=s07-support > /opt/course/s07-rbac/app.log
kubectl auth can-i create pods/payments --subresource=exec -n s07-apps --as=tom --as-group=s07-support > /opt/course/s07-rbac/exec-payments.txt
chown -R candidate: /opt/course/s07-rbac
