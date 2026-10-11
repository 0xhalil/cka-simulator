There are three errors (two break the build, one is silent):

1. `base/kustomization.yaml` → there is no file `svc.yaml`; the file is `service.yaml`.
2. The `limits.yaml` patch targets `metadata.name: webapp` → `no matches for Id Deployment.v1.apps/webapp`. Patches match by the **original name in the base** (`web`) (without prefix).
3. `images: - name: docker.io/library/nginx` → no error, but changes nothing: the images transformer matches the image name in the manifest **exactly** (`image: nginx`). The result is `nginx` (latest). The correct form is `name: nginx`.

```bash
ssh cka-cp1
cd /opt/course/s13-fix
k kustomize overlays/prod               # read the error messages one by one
sed -i 's/- svc.yaml/- service.yaml/' base/kustomization.yaml
sed -i 's/name: webapp/name: web/' overlays/prod/limits.yaml
vi overlays/prod/kustomization.yaml      # images: [{name: nginx, newTag: 1.27-alpine}]
k kustomize overlays/prod | grep -E 'replicas|image|memory|name: prod-web-env'
k apply -k overlays/prod
k -n s13-fix get deploy,svc,cm,endpointslice
```
Note: configMapGenerator adds a hash to the ConfigMap (`prod-web-env-xxxxx`) and automatically updates the `configMapRef` reference in the Deployment.
