The manifests of the *bookshop* application are stored in the directories `api/`, `cache/` and `web/` below `/opt/course/s13-dirs/k8s/`. Until now every directory was applied separately with `kubectl apply -f`.

Restructure it with Kustomize:

1. Create a `kustomization.yaml` in **each** of the three sub-directories that lists the manifests of that directory. The file `cache/legacy-configmap.yaml` must **not** be part of any build.
2. Create a root `kustomization.yaml` in `/opt/course/s13-dirs/k8s/` that includes the three **sub-directories** (not the individual manifest files) and
   - puts all resources into namespace `s13-dirs`,
   - adds the label `app.kubernetes.io/part-of: bookshop` to all resources **without** changing any selector.
3. Deploy everything with a **single** `kubectl` command from the root directory. Don't modify the existing manifest files.
