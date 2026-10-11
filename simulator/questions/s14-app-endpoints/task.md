In namespace `s14-relay` the Deployment `relay` (3 replicas) is exposed inside the cluster by the Service `relay-svc` on port `80`. Clients calling `http://relay-svc.s14-relay` get *connection refused* / timeouts, although the team says "the Pods are running".

Troubleshoot and fix the problem so that:

- all 3 `relay` Pods are `Ready`,
- `relay-svc` load-balances to all 3 Pods,
- a request to `http://relay-svc.s14-relay` from any Pod in the cluster returns the default httpd page (`It works!`).

Do **not** delete or recreate the Deployment or the Service, and keep the readiness probe of the `relay` container.
