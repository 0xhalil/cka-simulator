The platform team wants to cap the size of Deployments in **production** namespaces (namespaces labeled `env=prod`) on cluster `cka-cp2`. Use the built-in `ValidatingAdmissionPolicy` feature (no webhooks).

1. Create a `ValidatingAdmissionPolicy` named `vap-replica-cap`:
   - it must be evaluated for **CREATE** and **UPDATE** of `apps` Deployments - **including scaling** them (e.g. with `kubectl scale`)
   - validation (CEL): `spec.replicas` must be `<= 5`
   - message: `replicas must not exceed 5 in production`
   - `failurePolicy: Fail`
2. Create a `ValidatingAdmissionPolicyBinding` named `vap-replica-cap-binding` that **denies** violating requests, but only in namespaces labeled `env=prod`.
3. Deployment `legacy-batch` in namespace `vap-prod` currently violates the rule. Make it compliant by setting it to the **maximum allowed** number of replicas.

Namespaces `vap-prod` (`env=prod`) and `vap-dev` (`env=dev`) exist for testing.
