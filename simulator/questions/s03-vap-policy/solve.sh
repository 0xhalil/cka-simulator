cat <<'YAML' | kubectl apply -f -
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
      resources: ["deployments", "deployments/scale"]
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
YAML
sleep 3
kubectl -n vap-prod scale deploy legacy-batch --replicas=5
