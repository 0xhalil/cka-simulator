In namespace `resources` there is a Deployment `web-portal` with 3 replicas. Its Pods are pinned to node `cka-w1`, but currently only some of them can be scheduled.

Adjust the resource **requests** of all containers of the Pod template:

- Divide the node's **remaining** allocatable CPU and memory (after what other Pods on `cka-w1` already request) **evenly** across the 3 Pods, leaving some overhead so the node stays stable.
- Use the **exact same** requests for the init container and the main container.
- You may scale the Deployment to 0 before updating the resource requests.

When done, all 3 replicas must be `Running` on `cka-w1`. Do not change the node selector, the images or any other Deployment.
