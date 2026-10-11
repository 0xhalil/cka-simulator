kubectl delete pc high-priority --ignore-not-found >/dev/null
reset_ns priority
cat <<'YAML' | kubectl apply -f -
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: batch-low}
value: 1000
description: "batch jobs"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: team-critical}
value: 870000
description: "critical team services"
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata: {name: web-standard}
value: 50000
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: busybox-logger, namespace: priority}
spec:
  replicas: 1
  selector: {matchLabels: {app: busybox-logger}}
  template:
    metadata: {labels: {app: busybox-logger}}
    spec:
      containers:
      - name: logger
        image: busybox:1.36
        command: ["sh", "-c", "while true; do date; sleep 10; done"]
        resources: {requests: {cpu: 10m, memory: 16Mi}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: report-worker, namespace: priority}
spec:
  replicas: 1
  selector: {matchLabels: {app: report-worker}}
  template:
    metadata: {labels: {app: report-worker}}
    spec:
      priorityClassName: batch-low
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh", "-c", "sleep 1d"]
        resources: {requests: {cpu: 10m, memory: 16Mi}}
YAML
