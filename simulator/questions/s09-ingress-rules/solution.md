```bash
ssh cka-cp1
k -n s09-shop get svc            # shop-pay port is 8282 (not 80!)
k -n s09-shop create secret tls shop-tls --cert=/opt/course/s09-ingress/shop.crt --key=/opt/course/s09-ingress/shop.key
k -n s09-shop create ingress shop --class=nginx \
  --rule="shop.s09.local/pay*=shop-pay:8282,tls=shop-tls" \
  --rule="shop.s09.local/status=shop-ui:80" \
  --rule="shop.s09.local/*=shop-ui:80" \
  --default-backend=shop-default:80 \
  --annotation=nginx.ingress.kubernetes.io/rewrite-target=/ $do > ing.yaml
k apply -f ing.yaml
k -n s09-shop describe ingress shop
```
(`path*` → `pathType: Prefix`, without the asterisk → `Exact`.)

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  defaultBackend:
    service: {name: shop-default, port: {number: 80}}
  tls:
  - hosts: [shop.s09.local]
    secretName: shop-tls
  rules:
  - host: shop.s09.local
    http:
      paths:
      - {path: /pay,    pathType: Prefix, backend: {service: {name: shop-pay, port: {number: 8282}}}}
      - {path: /status, pathType: Exact,  backend: {service: {name: shop-ui,  port: {number: 80}}}}
      - {path: /,       pathType: Prefix, backend: {service: {name: shop-ui,  port: {number: 80}}}}
```
Notes: without `rewrite-target: /` a `/pay` request reaches the backend as `/pay` (404). `defaultBackend` handles requests that match no rule; the `/` Prefix path only applies to the `shop.s09.local` host.
