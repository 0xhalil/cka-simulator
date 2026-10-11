kubectl -n s02-imp run nginx-prod --image=nginx:1.27-alpine --labels=tier=web,env=prod
kubectl -n s02-imp run httpd-edge --image=httpd:2.4-alpine --port=80
kubectl -n s02-imp expose pod httpd-edge --port=8080 --target-port=80
kubectl create ns s02-imp-dev
kubectl -n s02-imp-dev create deploy cache --image=redis:7-alpine --replicas=2
kubectl -n s02-imp create deploy worker --image=busybox:1.36 --replicas=3 --dry-run=client -o yaml -- sleep 3600 > /opt/course/s02-imp/worker.yaml
kubectl -n s02-imp wait --for=condition=Ready pod --all --timeout=90s
kubectl -n s02-imp-dev rollout status deploy cache --timeout=120s
