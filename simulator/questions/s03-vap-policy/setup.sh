fresh_control_plane
kubectl delete validatingadmissionpolicybinding vap-replica-cap-binding --ignore-not-found >/dev/null 2>&1
kubectl delete validatingadmissionpolicy vap-replica-cap --ignore-not-found >/dev/null 2>&1
reset_ns vap-prod vap-dev
kubectl label ns vap-prod env=prod --overwrite >/dev/null
kubectl label ns vap-dev env=dev --overwrite >/dev/null
cat <<'YAML' | kubectl apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata: {name: legacy-batch, namespace: vap-prod}
spec:
  replicas: 8
  selector: {matchLabels: {app: legacy-batch}}
  template:
    metadata: {labels: {app: legacy-batch}}
    spec:
      tolerations: [{key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}]
      containers:
      - name: app
        image: busybox:1.36
        command: ["sleep", "1d"]
        resources: {requests: {cpu: 1m, memory: 4Mi}}
YAML
