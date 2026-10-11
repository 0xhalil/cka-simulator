Map the app end to end (user → web-service → web pod → catalog Service → catalog pod) and check each link one by one. There are three independent errors:

1. **web pod CrashLoopBackOff**: `kubectl logs` → `host not found in upstream "catalog-service"`. Env is `DB_HOST=catalog-service` but the Service is named `catalog`. Fix the env (or create a Service named `catalog-service`).
2. **catalog Service targetPort 8080**, while httpd listens on 80 → endpoints exist but `502 Bad Gateway`. `targetPort: 80`.
3. **web-service selector `app: web-frontend`** → no endpoints. The pod label is `app: web`.

Trap: don't stop once the web pod is fixed thinking "the app is up" — the 502 still points to the DB side. Always check the endpoints.

```bash
k -n s14-shop get deploy,po,svc,endpointslice -o wide
k -n s14-shop logs deploy/web            # host not found in upstream "catalog-service"
k -n s14-shop set env deploy/web DB_HOST=catalog
k -n s14-shop edit svc catalog           # targetPort: 80
k -n s14-shop edit svc web-service       # selector: app: web
k -n s14-shop get endpointslice
curl http://192.168.104.3:31401          # CATALOG-DB-OK
```
