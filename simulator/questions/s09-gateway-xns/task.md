The platform team operates the Gateway `shared-gw` in namespace `s09-gw-infra` (GatewayClass `nginx`, listener `http`, hostname `portal.s09.local`). The portal team works in namespace `s09-gw-team`; their backend Service `portal-api` (port `80`) lives in namespace `s09-gw-backend`.

1. Allow HTTPRoutes to attach to listener `http` of `shared-gw` **only** from namespaces that carry the label `gateway-access=true`, and give that label to namespace `s09-gw-team`. Don't change anything else on the Gateway.
2. Create an HTTPRoute `portal-route` in namespace `s09-gw-team` attached to `shared-gw` for hostname `portal.s09.local`:
   - Requests with path prefix `/api` are sent to Service `portal-api` port `80` in namespace `s09-gw-backend`.
   - Requests with path prefix `/legacy` are answered with an HTTP **301** redirect to the same URL with the prefix `/legacy` replaced by `/api` (e.g. `/legacy/x` → `/api/x`).
3. Make the cross-namespace reference work **without** moving the Service: create the required object named `allow-portal-team` in the namespace of the Service. It must permit only HTTPRoutes from namespace `s09-gw-team` to reference Services.

Test via the NodePort Service the Gateway controller created for `shared-gw` in namespace `s09-gw-infra`:
`curl -i -H 'Host: portal.s09.local' http://<nodeIP>:<nodePort>/api/`
