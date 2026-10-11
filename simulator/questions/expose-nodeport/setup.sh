reset_ns sp-culator
kubectl -n sp-culator create deploy front-end --image=nginx:1.27-alpine --replicas=2 >/dev/null
kubectl -n sp-culator patch deploy front-end --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/name","value":"nginx"}]' >/dev/null
