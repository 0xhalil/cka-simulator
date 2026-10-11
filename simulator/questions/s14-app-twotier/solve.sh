kubectl -n s14-shop set env deploy/web DB_HOST=catalog
kubectl -n s14-shop patch svc catalog --type=json -p '[{"op":"replace","path":"/spec/ports/0/targetPort","value":80}]'
kubectl -n s14-shop patch svc web-service --type=json -p '[{"op":"replace","path":"/spec/selector","value":{"app":"web"}}]'
kubectl -n s14-shop rollout status deploy/web --timeout=120s
