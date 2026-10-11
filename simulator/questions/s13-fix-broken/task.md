A colleague prepared the Kustomize overlay `/opt/course/s13-fix/overlays/prod`, but `kubectl apply -k` fails, and even their local fixes did not produce the expected result.

Repair the configuration so that applying the overlay results in the following in namespace `s13-fix`:

- Deployment `prod-web` with **3** Ready replicas running `nginx:1.27-alpine`, with a memory **limit** of `64Mi` on container `web`,
- the container gets `MODE=production` from the generated ConfigMap (name prefix `prod-web-env`),
- Service `prod-web` with 3 ready endpoints.

Rules: don't modify `base/deployment.yaml` and `base/service.yaml`; keep the existing approach (image transformer, replicas transformer, ConfigMap generator and the patch file `limits.yaml`). Apply the overlay with `kubectl`.
