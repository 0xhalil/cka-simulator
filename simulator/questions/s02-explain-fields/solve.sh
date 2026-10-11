cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: toolbox, namespace: s02-explain}
spec:
  shareProcessNamespace: true
  enableServiceLinks: false
  terminationGracePeriodSeconds: 5
  hostAliases:
  - ip: 10.10.10.10
    hostnames: [legacy-db, legacy-db.internal]
  containers:
  - name: shell
    image: busybox:1.36
    command: [sleep, "3600"]
YAML
cat > /opt/course/s02-explain/fields.txt <<'TXT'
HISTORY=spec.revisionHistoryLimit
READY=spec.minReadySeconds
DEADLINE=spec.progressDeadlineSeconds
TXT
kubectl -n s02-explain wait --for=condition=Ready pod/toolbox --timeout=90s
