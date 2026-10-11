Namespace `s09-canary` runs two versions of an application, exposed by the Services `app-v1` and `app-v2` (both port `80`). Release a canary using the **Gateway API** (GatewayClass `nginx` is installed):

1. Create a Gateway `canary-gw` in namespace `s09-canary` with a single **HTTP** listener named `http` on port `80` for hostname `canary.s09.local`.
2. Create an HTTPRoute `canary-route` in namespace `s09-canary`, attached to `canary-gw`, for hostname `canary.s09.local`:
   - Requests carrying the header `X-Canary: always` must **always** go to `app-v2`, and their responses must get the additional response header `X-Canary-Served: "true"`.
   - All other requests (any path) are split **80 %** to `app-v1` and **20 %** to `app-v2`.

Test via the NodePort Service the Gateway controller creates for `canary-gw`:
`curl -H 'Host: canary.s09.local' http://<nodeIP>:<nodePort>/`
