A CI pipeline needs access to the cluster.

1. Create a ServiceAccount `pipeline` in namespace `cicd`.
2. Create a **ClusterRole** `pipeline-deployer` that allows the verbs `get`, `list`, `create`, `update` and `patch` on `deployments` and `statefulsets`, and `get`, `list` on `pods`.
3. Grant the ServiceAccount these permissions **only in namespaces `cicd` and `staging`** (both exist). It must have **no** such permissions in any other namespace.
4. Change the existing Deployment `runner` in namespace `cicd` so its Pods run as ServiceAccount `pipeline`.

Write the output of
`kubectl auth can-i create deployments --as=system:serviceaccount:cicd:pipeline -n staging`
into `/opt/course/rbac/can-i.txt`.
