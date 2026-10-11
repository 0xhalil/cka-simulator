**backend:** There are two traps.
1. The image in the template is wrong (`httpd:2.4-alpinee`). Fixing the ReplicaSet template **does not update existing Pods** — a ReplicaSet (unlike a Deployment) doesn't do rollouts; you have to delete the old Pods.
2. The bare Pod `backend-legacy` has the `tier=backend` label, so it was **adopted** by the ReplicaSet and counts as one of the 3 replicas; it runs busybox. You must delete it too.

```bash
ssh cka-cp1
k -n s02-rs get rs,pod --show-labels
k -n s02-rs get pod backend-legacy -o jsonpath='{.metadata.ownerReferences}'
k -n s02-rs set image rs/backend httpd=httpd:2.4-alpine     # or k edit rs backend
k -n s02-rs delete pod -l tier=backend                      # legacy + broken pods
k -n s02-rs get pod -l tier=backend -o wide
```

**frontend:** Two errors in the manifest: `apiVersion: v1` should be `apps/v1` (`kubectl explain replicaset` → GROUP apps), and the template label (`app: front-end`) doesn't match the selector (`app: frontend`) → the API returns a `selector does not match template labels` error.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
...
  template:
    metadata:
      labels:
        app: frontend
```
```bash
vim /opt/course/s02-rs/frontend-rs.yaml
k apply -f /opt/course/s02-rs/frontend-rs.yaml
k -n s02-rs get rs frontend
```
