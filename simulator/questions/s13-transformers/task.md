A Kustomize base exists at `/opt/course/s13-trans/base`. Its Deployment uses the placeholder image `web-server`, which does not exist in any registry.

Create a kustomization at `/opt/course/s13-trans/release/kustomization.yaml` that uses the base (do **not** modify any file in `base`) and, using Kustomize transformers only (no patches):

- deploys everything into namespace `s13-trans`,
- prefixes all resource names with `blue-` and suffixes them with `-v2` (e.g. Service `blue-web-v2`),
- adds the annotation `owner: team-blue` to all resources,
- adds the label `release: r2` to all resources **and** to the Deployment's Pod selector / template and the Service selector,
- replaces the image `web-server` with `nginx:1.27-alpine`,
- runs `2` replicas of the Deployment.

Apply it to the cluster. The Service `blue-web-v2` must have 2 ready endpoints, and the Pods must still load the (renamed) ConfigMap.
