There are three separate blockers: (1) listener `allowedRoutes: from: Same` → a route in another namespace can't attach, (2) the route's backend is in another namespace → a **ReferenceGrant** is needed in the target namespace, (3) a redirect is a **filter** (no backendRefs).

```bash
ssh cka-cp1
k label ns s09-gw-team gateway-access=true
k -n s09-gw-infra edit gateway shared-gw
#   listeners:
#   - name: http
#     ...
#     allowedRoutes:
#       namespaces:
#         from: Selector
#         selector:
#           matchLabels: {gateway-access: "true"}
```
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: ReferenceGrant
metadata: {name: allow-portal-team, namespace: s09-gw-backend}   # in the TARGET (Service) namespace
spec:
  from:
  - {group: gateway.networking.k8s.io, kind: HTTPRoute, namespace: s09-gw-team}
  to:
  - {group: "", kind: Service}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: portal-route, namespace: s09-gw-team}
spec:
  parentRefs: [{name: shared-gw, namespace: s09-gw-infra, sectionName: http}]
  hostnames: [portal.s09.local]
  rules:
  - matches: [{path: {type: PathPrefix, value: /api}}]
    backendRefs: [{name: portal-api, namespace: s09-gw-backend, port: 80}]
  - matches: [{path: {type: PathPrefix, value: /legacy}}]
    filters:
    - type: RequestRedirect
      requestRedirect:
        statusCode: 301
        path: {type: ReplacePrefixMatch, replacePrefixMatch: /api}
```
```bash
k -n s09-gw-team describe httproute portal-route    # Accepted / ResolvedRefs (RefNotPermitted = ReferenceGrant missing)
NP=$(k -n s09-gw-infra get svc -l gateway.networking.k8s.io/gateway-name=shared-gw -o jsonpath='{.items[0].spec.ports[0].nodePort}')
curl -i -H 'Host: portal.s09.local' http://<nodeIP>:$NP/api/
curl -i -H 'Host: portal.s09.local' http://<nodeIP>:$NP/legacy/x    # 301 Location: http://portal.s09.local/api/x
```
Trap: the ReferenceGrant is created in the namespace of the referenced resource (Service), not the route's. Without `allowedRoutes` the route is rejected with `NotAllowedByListeners`.
