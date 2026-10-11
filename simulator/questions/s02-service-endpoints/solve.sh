kubectl -n s02-svc patch svc orders-svc --type=json -p '[{"op":"replace","path":"/spec/selector","value":{"app":"orders","track":"stable"}},{"op":"replace","path":"/spec/ports/0/targetPort","value":"web"}]'
sleep 5
kubectl -n s02-svc get endpointslice -l kubernetes.io/service-name=orders-svc -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{"\n"}{end}' > /opt/course/s02-svc/endpoints.txt
cat /opt/course/s02-svc/endpoints.txt
