Once each subdirectory has its own `kustomization.yaml`, the root kustomization just references the directories (Managing Directories).

```bash
ssh cka-cp1
cd /opt/course/s13-dirs/k8s
for d in api web cache; do cat > $d/kustomization.yaml <<'Y'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
Y
done                                  # cache: legacy-configmap.yaml is NOT in the list
```
```yaml
# /opt/course/s13-dirs/k8s/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: s13-dirs
labels:                       # includeSelectors defaults to false -> selectors stay unchanged
- pairs:
    app.kubernetes.io/part-of: bookshop
resources:
- api
- cache
- web
```
```bash
k kustomize .            # check
k apply -k .
k -n s13-dirs get deploy,svc --show-labels
```
Trap: `commonLabels` also adds the label to selectors (not wanted). Kustomize doesn't pick up files in a directory automatically — only those in the `resources` list get into the build.
