```bash
ssh cka-cp1
k -n s05-rollout rollout history deploy web          # CHANGE-CAUSE column
k -n s05-rollout rollout history deploy web --revision=4   # image: nginx:1.27-alpine-hotfix (doesn't exist) -> ErrImagePull
echo 4 > /opt/course/s05-rollout/broken-revision.txt
k -n s05-rollout rollout undo deploy web --to-revision=2
k -n s05-rollout edit deploy web
```
```yaml
spec:
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate: {maxSurge: 1, maxUnavailable: 0}
```
```bash
k -n s05-rollout rollout status deploy web
k -n s05-rollout rollout history deploy web          # revision 2 now shows up as 5
```
Trap: `rollout undo` without parameters goes back to the previous revision (3 = "release v3"), which is not what's required. A rollback creates a new revision number (2 → 5) and the change-cause comes back too. Changing strategy/revisionHistoryLimit doesn't change the pod template, so it doesn't create a new revision.
