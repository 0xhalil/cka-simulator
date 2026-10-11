echo cache.s02-backend.svc.cluster.local > /opt/course/s02-dns/fqdn.txt
kubectl -n s02-frontend create quota frontend-quota --hard=pods=6,requests.cpu=500m,requests.memory=512Mi
kubectl -n s02-frontend set resources deploy webapp --requests=cpu=10m,memory=16Mi
kubectl -n s02-frontend set env deploy webapp CACHE_HOST=cache.s02-backend.svc.cluster.local
kubectl -n s02-frontend rollout status deploy webapp --timeout=120s
