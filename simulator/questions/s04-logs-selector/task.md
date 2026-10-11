The Deployment `worker` in namespace `s04-agg` runs 3 replicas; every Pod has two containers. A second Deployment `worker-legacy` runs in the same namespace.

1. Write the logs of **all containers of all Pods of Deployment `worker`** (and of no other Pods) into `/opt/course/s04-agg/worker.log`. Every line must be prefixed with the name of the Pod (and container) it came from, as `kubectl` can do it.
2. Write the total number of lines containing `WARN` across all those logs into `/opt/course/s04-agg/warn-count.txt` (only the number).
