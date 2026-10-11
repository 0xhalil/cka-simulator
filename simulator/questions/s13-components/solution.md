A Component is a reusable config block for features wanted in only a subset of the overlays. A directory referenced under `components:` **must** be `kind: Component` (apiVersion `kustomize.config.k8s.io/v1alpha1`) — `external-db` was mistakenly defined as a `Kustomization`.

```yaml
# components/external-db/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patches: [...]          # content stays the same
```
```yaml
# components/caching/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
resources:
- redis.yaml            # redis-cache Deployment (container redis, redis:7-alpine) + Service 6379
patches:
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: shop
    spec:
      template:
        spec:
          containers:
          - name: shop
            env:
            - name: CACHE_HOST
              value: redis-cache
```
```yaml
# overlays/premium/kustomization.yaml
components:
- ../../components/external-db
- ../../components/caching
# overlays/selfhosted/kustomization.yaml
components:
- ../../components/caching
```
```bash
ssh cka-cp1
cd /opt/course/s13-comp
for o in dev premium selfhosted; do echo "== $o"; k kustomize overlays/$o | grep -E '^kind|name: (CACHE|DB)_HOST'; done
k apply -k overlays/dev
k apply -k overlays/premium
k -n s13-comp-premium get deploy,svc
```
Trap: the patch in the Component is applied to the base's resource; the env list is merged by the `name` merge key, so `SHOP_MODE` is preserved.
