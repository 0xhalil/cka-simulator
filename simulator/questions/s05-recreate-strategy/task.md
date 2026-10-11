The Deployment `ledger` in namespace `s05-recreate` runs 3 replicas. Its Pods have two containers: `app` and `log-agent`. The application cannot run two different versions at the same time.

1. Change the Deployment so that during an update **all old Pods are terminated before new Pods are created**.
2. Update **only** the image of container `app` to `nginx:1.28-alpine`. The container `log-agent` must keep its image.
3. The new revision must have the change-cause `upgrade app to 1.28` (visible in `kubectl rollout history`).
4. When the rollout has finished, write the Deployment's current revision number into `/opt/course/s05-recreate/revision.txt`.

Do not delete or recreate the Deployment.
