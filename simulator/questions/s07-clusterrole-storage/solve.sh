cat <<'YAML' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata: {name: s07-storage-admin}
rules:
- apiGroups: [""]
  resources: [nodes]
  verbs: [get, list, watch]
- apiGroups: [""]
  resources: [persistentvolumes]
  verbs: [get, list, watch, create, delete]
- apiGroups: [storage.k8s.io]
  resources: [storageclasses]
  verbs: [get, list, watch]
YAML
kubectl create clusterrolebinding s07-storage-admin --clusterrole=s07-storage-admin --user=s07-alice
# remove only alice from the legacy binding
IDX=$(kubectl get clusterrolebinding s07-infra-legacy -o json | python3 -c 'import json,sys; s=json.load(sys.stdin)["subjects"]; print([i for i,x in enumerate(s) if x["name"]=="s07-alice"][0])')
kubectl patch clusterrolebinding s07-infra-legacy --type=json -p "[{\"op\":\"remove\",\"path\":\"/subjects/$IDX\"}]"
kubectl auth can-i delete nodes --as=s07-alice > /opt/course/s07-clusterrole/delete-nodes.txt
kubectl auth can-i create persistentvolumes --as=s07-alice > /opt/course/s07-clusterrole/create-pv.txt
chown -R candidate: /opt/course/s07-clusterrole
