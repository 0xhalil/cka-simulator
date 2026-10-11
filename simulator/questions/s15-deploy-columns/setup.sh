reset_ns s15-deploy
course_dir s15-deploy
mk() {  # name image replicas
  kubectl -n s15-deploy create deploy $1 --image=$2 --replicas=$3 >/dev/null
  kubectl -n s15-deploy set resources deploy $1 --requests=cpu=1m,memory=8Mi >/dev/null
  sleep 1.5
}
mk web-frontend nginx:1.27-alpine 2
mk cache-redis redis:7-alpine 1
mk zeta-batch busybox:1.36.99 1
mk api-gateway httpd:2.4-alpine 1
mk metrics-proxy nginx:1.27-alpine 1
kubectl -n s15-deploy patch deploy zeta-batch --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/command","value":["sleep","360000"]}]' >/dev/null
for d in web-frontend cache-redis api-gateway metrics-proxy; do wait_deploy s15-deploy $d 120s; done
true
