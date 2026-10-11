Namespace `s09-shop` contains the Services `shop-ui`, `shop-pay` and `shop-default`. The cluster will use the **ingress-nginx** controller (IngressClass `nginx`).

1. Create a TLS Secret `shop-tls` in namespace `s09-shop` from the certificate `/opt/course/s09-ingress/shop.crt` and key `/opt/course/s09-ingress/shop.key`.
2. Create an Ingress `shop` in namespace `s09-shop` using IngressClass `nginx` for host `shop.s09.local`:
   - HTTPS is terminated with the Secret `shop-tls` for host `shop.s09.local`.
   - Requests to `/pay` and everything below it go to Service `shop-pay` (use its correct port). The payment app only serves content at `/`, so the controller must **rewrite** the matched request path to `/` before forwarding.
   - Requests to exactly `/status` (and **only** that path) go to Service `shop-ui` port `80`.
   - All other requests for `shop.s09.local` go to Service `shop-ui` port `80`.
   - Requests that match **no rule at all** (e.g. other hosts) go to Service `shop-default` port `80`.

Note: no ingress controller is running in this cluster; your Ingress is graded on its specification.
