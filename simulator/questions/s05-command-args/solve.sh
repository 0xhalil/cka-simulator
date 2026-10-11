kubectl -n s05-cmd patch deploy sleeper --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/command","value":["sleep","3600"]}]'
kubectl -n s05-cmd run cache --image=redis:7-alpine -- redis-server --port 6380 --maxmemory 32mb
kubectl -n s05-cmd rollout status deploy sleeper --timeout=90s
kubectl -n s05-cmd wait --for=condition=Ready pod/cache --timeout=120s
