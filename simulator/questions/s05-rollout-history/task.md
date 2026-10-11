The Deployment `web` in namespace `s05-rollout` has been updated several times. The latest update is broken and the rollout is stuck.

1. Find the revision number of the broken release and write it into `/opt/course/s05-rollout/broken-revision.txt`.
2. Roll the Deployment back to the revision whose change-cause is `release v2-stable`. Do not delete or recreate the Deployment.
3. Change the update strategy so that during future rolling updates **at most one** additional Pod is created and **no** Pod becomes unavailable.
4. Configure the Deployment to keep at most `5` old ReplicaSets for rollback.

When done, all 4 replicas must be up to date and ready.
