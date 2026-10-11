```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: vap-replica-cap
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments", "deployments/scale"]   # scale subresource is separate!
  validations:
  - expression: "object.spec.replicas <= 5"
    message: "replicas must not exceed 5 in production"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: vap-replica-cap-binding
spec:
  policyName: vap-replica-cap
  validationActions: [Deny]
  matchResources:
    namespaceSelector:
      matchLabels:
        env: prod
```

```bash
k apply -f vap.yaml
k -n vap-prod scale deploy legacy-batch --replicas=5
# test
k -n vap-prod scale deploy legacy-batch --replicas=7 --dry-run=server   # denied
k -n vap-dev create deploy t --image=busybox:1.36 --replicas=6 --dry-run=server   # allowed
```

Traps:
- `kubectl scale` goes to the **`deployments/scale`** subresource; if you only list `deployments`, the rule can be bypassed via scale. The Scale object also has `spec.replicas`, so the same CEL expression works.
- The policy alone does nothing, a **binding** is required; `validationActions: [Deny]` (Warn/Audit don't block).
- Existing objects are not checked retroactively → `legacy-batch` must be scaled down to 5 manually.
