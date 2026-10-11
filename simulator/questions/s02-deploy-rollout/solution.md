**payment:** `rollout history` shows three revisions. Trap: a plain `kubectl rollout undo` goes back to the previous revision (2) — but revision 2 is broken too (wrong `command`, container CrashLoop). The last working revision is **1**.

```bash
ssh cka-cp1
k -n s02-deploy rollout history deploy payment
k -n s02-deploy rollout history deploy payment --revision=2     # command override -> crash
k -n s02-deploy rollout undo deploy payment --to-revision=1
k -n s02-deploy scale deploy payment --replicas=3
k -n s02-deploy rollout status deploy payment
```

**checkout:** First generate the YAML imperatively, then edit it (container name `web`, strategy and `revisionHistoryLimit`).

```bash
k -n s02-deploy create deploy checkout --image=httpd:2.4-alpine --replicas=3 $do > checkout.yaml
```
```yaml
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
    spec:
      containers:
      - name: web
        image: httpd:2.4-alpine
```
```bash
k apply -f checkout.yaml
k -n s02-deploy rollout status deploy checkout
k -n s02-deploy set image deploy/checkout web=httpd:2.4.68-alpine   # new revision, old RS is kept
k -n s02-deploy rollout history deploy checkout
```
Note: if you delete the Deployment and recreate it with the new image, the old revision (RS) is lost — rollback is no longer possible.
