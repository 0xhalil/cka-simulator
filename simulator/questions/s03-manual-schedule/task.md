In namespace `s03-manual` two Pods, `manual-web` and `manual-api`, are stuck in `Pending`. They were configured for a custom scheduler named `s03-offline-scheduler`, which has been decommissioned and will not come back.

Without deploying any scheduler and without changing the cluster's default scheduler:

1. Get Pod `manual-web` running on node `cka-w1`. You may delete and recreate it, but it must keep its name, labels, image and its `schedulerName` (`s03-offline-scheduler`).
2. Get Pod `manual-api` running on node `cka-w1` **without deleting or recreating it** — its UID must stay the same.

Do not modify node taints or labels.
