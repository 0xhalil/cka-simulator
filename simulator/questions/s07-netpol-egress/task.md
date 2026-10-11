Namespace `s07-np-app` runs three Deployments, each exposed by a Service of the same name:
`api` (label `app=api`, port 80), `db` (label `app=db`, port 6379) and `cache` (label `app=cache`, port 6379).
Namespace `s07-np-web` runs the Deployment `frontend` (Pods labeled `role=frontend`).

Secure namespace `s07-np-app` with NetworkPolicies (the CNI enforces them):

1. `default-deny-ingress`: denies **all incoming** traffic to all Pods in `s07-np-app`.
2. `api-policy` for the `api` Pods:
   - Ingress: only from Pods labeled `role=frontend` **that are in namespace `s07-np-web`**, only on TCP port 80.
   - Egress: only to the `db` Pods on TCP port 6379. DNS resolution (port 53, TCP and UDP) must keep working. All other outgoing traffic of the `api` Pods (e.g. to `cache` or the Kubernetes API) must be blocked.
3. `db-policy` for the `db` Pods: allow incoming traffic only from the `api` Pods on TCP port 6379.

Do not modify the Deployments, Services or Pod labels.
