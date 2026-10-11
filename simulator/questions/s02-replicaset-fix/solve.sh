F=/opt/course/s02-rs/frontend-rs.yaml
sed -i 's#^apiVersion: v1#apiVersion: apps/v1#; s#app: front-end#app: frontend#' $F
kubectl apply -f $F
kubectl -n s02-rs set image rs/backend httpd=httpd:2.4-alpine
kubectl -n s02-rs delete pod -l tier=backend --wait=false
sleep 5
kubectl -n s02-rs wait --for=condition=Ready pod -l tier=backend --timeout=120s
kubectl -n s02-rs wait --for=condition=Ready pod -l app=frontend --timeout=120s
