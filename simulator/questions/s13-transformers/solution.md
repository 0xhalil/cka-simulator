```yaml
# /opt/course/s13-trans/release/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../base
namespace: s13-trans
namePrefix: blue-
nameSuffix: -v2
commonAnnotations:
  owner: team-blue
commonLabels:            # also adds the label to selectors + Pod template
  release: r2
#  (alternative: labels: [{pairs: {release: r2}, includeSelectors: true}])
images:
- name: web-server       # image name in the manifest
  newName: nginx
  newTag: 1.27-alpine
replicas:
- name: web              # ORIGINAL name in the base (without prefix/suffix)
  count: 2
```
```bash
ssh cka-cp1
k kustomize /opt/course/s13-trans/release      # check the output first
k apply -k /opt/course/s13-trans/release
k -n s13-trans get deploy,svc,cm,endpointslice
```
Notes: namePrefix/nameSuffix also change the ConfigMap name, and Kustomize automatically updates the `configMapRef` reference in the Deployment. The `labels` field doesn't touch selectors without `includeSelectors: true`. The `replicas` and `images` transformers are not patches.
