Perform the following tasks:

1. Create a new PriorityClass named `high-priority` for user workloads with a value that is **exactly one less than the highest existing user-defined** priority class value.
2. Patch the existing Deployment `busybox-logger` running in the `priority` namespace to use the `high-priority` priority class.

Ensure that the `busybox-logger` Deployment rolls out successfully with the new priority class set. It is expected that Pods from other Deployments running in the `priority` namespace are evicted.

Do not modify other Deployments running in the `priority` namespace. Failure to do so may result in a reduced score.
