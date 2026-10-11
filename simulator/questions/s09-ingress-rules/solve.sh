kubectl -n s09-shop create secret tls shop-tls --cert=/opt/course/s09-ingress/shop.crt --key=/opt/course/s09-ingress/shop.key --dry-run=client -o yaml | kubectl apply -f -
cat <<'YAML' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shop
  namespace: s09-shop
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
      - path: /pay
        pathType: Prefix
        backend: {service: {name: shop-pay, port: {number: 8282}}}
      - path: /status
        pathType: Exact
        backend: {service: {name: shop-ui, port: {number: 80}}}
      - path: /
        pathType: Prefix
        backend: {service: {name: shop-ui, port: {number: 80}}}
YAML
