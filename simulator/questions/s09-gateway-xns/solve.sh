kubectl label ns s09-gw-team gateway-access=true --overwrite
kubectl -n s09-gw-infra patch gateway shared-gw --type=json -p '[{"op":"replace","path":"/spec/listeners/0/allowedRoutes","value":{"namespaces":{"from":"Selector","selector":{"matchLabels":{"gateway-access":"true"}}}}}]'
cat <<'YAML' | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: ReferenceGrant
metadata: {name: allow-portal-team, namespace: s09-gw-backend}
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
YAML
sleep 10
