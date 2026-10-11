In namespace `s02-svc` the Deployment `orders` (the stable version of the orders API) is running, together with a Deployment `orders-canary` that is still being tested.

The ClusterIP Service `orders-svc` should make the stable orders API reachable inside the cluster on port `8080`, but requests to it currently fail.

- Fix the Service `orders-svc` (keep its name, type `ClusterIP` and port `8080`) so that it forwards to the web server port of the Pods of Deployment `orders` — and **only** to those Pods (the canary must not receive any traffic).
- Do not modify the Deployments.
- Write the names of the Pods that are endpoints of `orders-svc` after your fix, one per line, into `/opt/course/s02-svc/endpoints.txt`.
