kubectl -n s05-init expose deploy orders-db --name=orders-db --port=6379
kubectl -n s05-init patch deploy orders --type=strategic -p '
spec:
  template:
    spec:
      volumes: [{name: work, emptyDir: {}}]
      initContainers:
      - name: wait-for-db
      - name: migrate
        volumeMounts: [{name: work, mountPath: /work}]
      containers:
      - name: orders
        volumeMounts: [{name: work, mountPath: /work}]
'
kubectl -n s05-init rollout status deploy orders --timeout=120s
