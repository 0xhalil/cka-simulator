kubectl -n cicd create sa pipeline
cat <<'YAML' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata: {name: pipeline-deployer}
rules:
- apiGroups: [apps]
  resources: [deployments, statefulsets]
  verbs: [get, list, create, update, patch]
- apiGroups: [""]
  resources: [pods]
  verbs: [get, list]
YAML
kubectl -n cicd    create rolebinding pipeline-deployer --clusterrole=pipeline-deployer --serviceaccount=cicd:pipeline
kubectl -n staging create rolebinding pipeline-deployer --clusterrole=pipeline-deployer --serviceaccount=cicd:pipeline
kubectl -n cicd set serviceaccount deploy runner pipeline
kubectl -n cicd rollout status deploy runner
kubectl auth can-i create deployments --as=system:serviceaccount:cicd:pipeline -n staging > /opt/course/rbac/can-i.txt
