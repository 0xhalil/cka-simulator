The application in `/opt/course/s13-comp` has a `base` and three overlays: `dev`, `premium` and `selfhosted`. Optional features are implemented as Kustomize **components** in `/opt/course/s13-comp/components/`.

1. The overlays `dev` and `premium` use the component `external-db`, but they don't build anymore. Fix the component (keep its content/patch).
2. Create a new component `caching` in `/opt/course/s13-comp/components/caching/` that adds
   - a Deployment `redis-cache` (1 replica, image `redis:7-alpine`, container `redis`, label `app: redis-cache`) and a Service `redis-cache` exposing port `6379`,
   - the env variable `CACHE_HOST=redis-cache` to container `shop` of Deployment `shop`.
3. Enable `caching` in the overlays `premium` and `selfhosted` **only**. Do not copy the caching manifests into the overlays and don't modify `base`.
4. Apply the overlays `dev` and `premium` to the cluster (namespaces `s13-comp-dev` and `s13-comp-premium` already exist).
