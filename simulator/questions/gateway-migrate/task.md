You have an existing web application deployed in namespace `web-app`, exposed through an Ingress named `web`. Migrate it from Ingress to the **Gateway API** while maintaining HTTPS access.

A GatewayClass named `nginx` is installed in the cluster.

1. Create a Gateway named `web-gateway` in namespace `web-app` with hostname `gateway.web.k8s.local` that maintains the existing **TLS** and **listener** configuration from the existing Ingress `web`.
2. Create an HTTPRoute named `web-route` in namespace `web-app` with hostname `gateway.web.k8s.local` that maintains the existing **routing rules** from the Ingress `web`.
3. After verifying the new setup works, **delete** the Ingress `web`.

You can test the Gateway with:

```
curl -k --resolve gateway.web.k8s.local:<nodePort>:<nodeIP> https://gateway.web.k8s.local:<nodePort>/
```

where `<nodePort>` is the HTTPS NodePort of the Service the Gateway controller creates for `web-gateway` in namespace `web-app`.
