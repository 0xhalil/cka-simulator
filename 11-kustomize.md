# 11 — Kustomize Basics

Scope: `kustomization.yaml`, resources & directory management, common transformers (namePrefix, labels, namespace, commonAnnotations), images transformer, patches (strategic merge / JSON 6902, inline & file), base/overlay, components.

---

## Q1 — Build & apply a base (4%)

Directory `/opt/course/1/k8s/` contains `db/` and `api/` subdirectories each with a Deployment and a Service, but no kustomization files.

1. Create a root `kustomization.yaml` (and per-directory ones) so that `kubectl apply -k /opt/course/1/k8s/` deploys everything.
2. All resources must get the label `app.kubernetes.io/part-of=store` and be deployed into namespace `store`.
3. Save the rendered output to `/opt/course/1/out.yaml`.

<details><summary>Solution</summary>

```yaml
# /opt/course/1/k8s/db/kustomization.yaml
resources: [deployment.yaml, service.yaml]
---
# /opt/course/1/k8s/api/kustomization.yaml
resources: [deployment.yaml, service.yaml]
---
# /opt/course/1/k8s/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: store
labels:
- pairs: {app.kubernetes.io/part-of: store}
  includeSelectors: false
resources: [db/, api/]
```

```bash
k create ns store
k kustomize /opt/course/1/k8s/ > /opt/course/1/out.yaml
k apply -k /opt/course/1/k8s/
```

`commonLabels` is also added to selectors → since selectors are immutable on existing Deployments, apply may fail. `labels` + `includeSelectors: false` is safer (commonLabels is deprecated).
</details>

---

## Q2 — Image transformer & prefix (3%)

In `/opt/course/1/k8s/kustomization.yaml`:

1. Replace every `nginx` image with `nginx:1.27-alpine` and every `postgres` image with `registry.local/postgres:16` — **without editing the deployment files**.
2. Add name prefix `prod-`.

Verify only via `kubectl kustomize` (don't apply).

<details><summary>Solution</summary>

```yaml
namePrefix: prod-
images:
- name: nginx
  newTag: 1.27-alpine
- name: postgres
  newName: registry.local/postgres
  newTag: "16"
```

```bash
k kustomize /opt/course/1/k8s/ | grep -E 'image:|name: prod-'
```

When namePrefix changes a Service name, kustomize updates references within the same kustomization (e.g. `configMapRef` in the Deployment); but it does **not** update service names hardcoded in the application's env.
</details>

---

## Q3 — Patches (6%)

Base in `/opt/course/3/base` has Deployment `api` (1 replica, container `api`). Create kustomization patches (no edits to base files) so that:

1. Replicas become **4** (strategic merge patch, inline).
2. A second container `metrics` (`prom/statsd-exporter`) is **added** to the pod.
3. Using a **JSON 6902** patch, the first container's `image` is replaced with `api:2.0` and the label `tier` is **removed** from the Deployment's metadata.

<details><summary>Solution</summary>

```yaml
# /opt/course/3/base/kustomization.yaml (you can also create an overlay outside base)
resources: [deployment.yaml]
patches:
- target: {kind: Deployment, name: api}
  patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata: {name: api}
    spec:
      replicas: 4
      template:
        spec:
          containers:
          - name: metrics
            image: prom/statsd-exporter
- target: {kind: Deployment, name: api}
  patch: |-
    - op: replace
      path: /spec/template/spec/containers/0/image
      value: api:2.0
    - op: remove
      path: /metadata/labels/tier
```

```bash
k kustomize /opt/course/3/base | less
```

In a strategic merge, the containers list is merged by the `name` key → new name = add, same name = update. To delete a container: `- $patch: delete` + `name:`.
</details>

---

## Q4 — Base + overlays (6%)

Create this structure under `/opt/course/4/`:

```
base/        -> Deployment "web" (nginx, 1 replica) + Service "web"
overlays/dev -> namespace dev, replicas 1, label env=dev
overlays/prod-> namespace prod, replicas 5, label env=prod, image nginx:1.27,
               plus an extra ConfigMap "web-config" generated from literal MODE=prod
```

Apply both overlays. The ConfigMap name in prod must have a content hash suffix and the Deployment must reference it via `envFrom`.

<details><summary>Solution</summary>

```yaml
# overlays/prod/kustomization.yaml
resources: [../../base]
namespace: prod
labels: [{pairs: {env: prod}}]
replicas: [{name: web, count: 5}]
images: [{name: nginx, newTag: "1.27"}]
configMapGenerator:
- name: web-config
  literals: [MODE=prod]
patches:
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata: {name: web}
    spec:
      template:
        spec:
          containers:
          - name: nginx
            envFrom:
            - configMapRef: {name: web-config}   # kustomize converts it to the hashed name
```

```bash
k create ns dev; k create ns prod
k apply -k /opt/course/4/overlays/dev
k apply -k /opt/course/4/overlays/prod
k -n prod get cm                       # web-config-<hash>
k -n prod get deploy web -o jsonpath='{.spec.template.spec.containers[0].envFrom}'
```
</details>

---

## Q5 — Components (4%)

Overlays `dev` and `prod` from Q4 both need an optional **caching sidecar** (`redis:7`, container name `cache`), but `staging` (new overlay, namespace `staging`, 2 replicas) must not get it.

Implement the sidecar as a Kustomize **Component** at `/opt/course/4/components/cache` and include it in dev and prod only.

<details><summary>Solution</summary>

```yaml
# components/cache/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patches:
- patch: |-
    apiVersion: apps/v1
    kind: Deployment
    metadata: {name: web}
    spec:
      template:
        spec:
          containers:
          - name: cache
            image: redis:7
---
# overlays/dev/kustomization.yaml (same line for prod)
resources: [../../base]
components: [../../components/cache]
```

```bash
k kustomize /opt/course/4/overlays/dev | grep -A1 'name: cache'
k kustomize /opt/course/4/overlays/staging | grep cache    # empty
```

A Component's `apiVersion` is `v1alpha1` and `kind: Component` — not `Kustomization`.
</details>
