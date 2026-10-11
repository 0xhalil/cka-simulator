N=s14-gallery
kubectl -n $N patch deploy gallery --type=json -p '[
 {"op":"replace","path":"/spec/template/spec/containers/0/image","value":"nginx:1.27-alpine"},
 {"op":"replace","path":"/spec/template/spec/volumes/0/configMap/name","value":"gallery-config"}]'
kubectl -n $N patch svc gallery --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":8080}]'
kubectl -n $N rollout status deploy/gallery --timeout=120s
