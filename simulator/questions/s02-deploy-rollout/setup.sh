reset_ns s02-deploy
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment
  namespace: s02-deploy
  annotations: {kubernetes.io/change-cause: "initial release nginx:1.27-alpine"}
spec:
  replicas: 2
  selector: {matchLabels: {app: payment}}
  template:
    metadata: {labels: {app: payment}}
    spec:
      containers:
      - name: nginx
        image: nginx:1.27-alpine
        resources: {requests: {cpu: 5m, memory: 16Mi}}
YAML
wait_deploy s02-deploy payment 120s
# revision 2: broken config (container crashes)
kubectl -n s02-deploy patch deploy payment --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/command","value":["nginx","-g","daemon off;","-c","/etc/nginx/tuned.conf"]}]' >/dev/null
kubectl -n s02-deploy annotate deploy/payment kubernetes.io/change-cause="tune worker settings" --overwrite >/dev/null
sleep 8
# revision 3: non-existing image
kubectl -n s02-deploy set image deploy/payment nginx=nginx:1.27.99-alpine >/dev/null
kubectl -n s02-deploy annotate deploy/payment kubernetes.io/change-cause="upgrade to 1.27.99" --overwrite >/dev/null
kubectl annotate ns s02-deploy simulator/payment-uid="$(kubectl -n s02-deploy get deploy payment -o jsonpath='{.metadata.uid}')" --overwrite >/dev/null
