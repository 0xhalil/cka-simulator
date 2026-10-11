The short name `cache` only resolves within the **same namespace** (the Pod's `/etc/resolv.conf` search list starts with `s02-frontend.svc.cluster.local`). A Service in another namespace needs `<service>.<namespace>` or the FQDN `<service>.<namespace>.svc.cluster.local`.

Trap: when a ResourceQuota limits `requests.cpu` / `requests.memory`, **new Pods without requests are rejected** in that namespace (`must specify requests.cpu...`). After creating the quota, the env-change rollout can't create new Pods and gets stuck → add requests to the container (or provide defaults with a `LimitRange`).

```bash
ssh cka-cp1
k -n s02-frontend logs deploy/webapp        # cannot reach cache:6379
echo cache.s02-backend.svc.cluster.local > /opt/course/s02-dns/fqdn.txt

k -n s02-frontend create quota frontend-quota --hard=pods=6,requests.cpu=500m,requests.memory=512Mi
k -n s02-frontend set resources deploy webapp --requests=cpu=10m,memory=16Mi
k -n s02-frontend set env deploy webapp CACHE_HOST=cache.s02-backend.svc.cluster.local
k -n s02-frontend rollout status deploy webapp
k -n s02-frontend describe quota frontend-quota
k -n s02-frontend get rs        # is the new RS ready? any FailedCreate events?
```
