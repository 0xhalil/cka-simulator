```bash
ssh cka-cp1
k -n cicd create sa pipeline
k create clusterrole pipeline-deployer --verb=get,list,create,update,patch --resource=deployments.apps,statefulsets.apps
k edit clusterrole pipeline-deployer      # second rule: pods get,list
#  - apiGroups: [""]
#    resources: ["pods"]
#    verbs: ["get","list"]
# ClusterRole + RoleBinding = only that namespace (NOT a ClusterRoleBinding)
k -n cicd    create rolebinding pipeline-deployer --clusterrole=pipeline-deployer --serviceaccount=cicd:pipeline
k -n staging create rolebinding pipeline-deployer --clusterrole=pipeline-deployer --serviceaccount=cicd:pipeline
k -n cicd set serviceaccount deploy runner pipeline
k auth can-i create deployments --as=system:serviceaccount:cicd:pipeline -n staging > /opt/course/rbac/can-i.txt
```
