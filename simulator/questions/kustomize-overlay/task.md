A Kustomize base for an application exists at `/opt/course/kustomize/base`.

Create an overlay at `/opt/course/kustomize/overlays/prod` (do **not** modify any file in `base`) so that:

- all resources are deployed to namespace `shop-prod`,
- all resources get the label `env: prod`,
- the Deployment `api` runs **3** replicas,
- the container image `nginx` is replaced by `nginx:1.27-alpine`,
- a ConfigMap named `api-config` is **generated** with literal `LOG_LEVEL=warn`, and the `api` container loads it via `envFrom`.

Apply the overlay to the cluster using `kubectl` (namespace `shop-prod` already exists).
