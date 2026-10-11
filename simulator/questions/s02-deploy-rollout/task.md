Work in namespace `s02-deploy`.

**1.** Someone updated the Deployment `payment` and its rollout never finished. Roll the Deployment back to the **last revision that worked** (do not delete/recreate the Deployment), then scale it to **3** replicas. All 3 Pods must be ready.

**2.** Create a Deployment `checkout`:

- 3 replicas, Pod label `app=checkout`, one container named `web` with image `httpd:2.4-alpine`
- rolling update strategy that never takes a Pod down before its replacement is ready: `maxUnavailable: 0`, `maxSurge: 1`
- keep at most `5` old ReplicaSets for rollbacks

Once all 3 Pods are ready, perform a rolling update of the container `web` to image `httpd:2.4.68-alpine`. The rollout history must keep the previous revision (with `httpd:2.4-alpine`) available for a rollback.
