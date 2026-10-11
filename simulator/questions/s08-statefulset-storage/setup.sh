kubectl delete ns s08-kv --ignore-not-found --wait=true --timeout=120s >/dev/null 2>&1
kubectl delete sc s08-fast --ignore-not-found >/dev/null
kubectl create ns s08-kv >/dev/null
on cka-w1 'crictl pull docker.io/library/redis:7-alpine >/dev/null' || true
