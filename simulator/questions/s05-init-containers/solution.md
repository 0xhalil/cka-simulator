There are two separate errors:

1. `wait-for-db` waits forever because **there is no `orders-db` Service** (no DNS record).
2. `migrate` can't write `/work/migrated` (`/work` doesn't exist) and the main container can't see the file: **no shared volume**.

```bash
ssh cka-cp1
k -n s05-init get pod                                 # Init:0/2
k -n s05-init logs deploy/orders -c wait-for-db       # waiting for orders-db ...
k -n s05-init expose deploy orders-db --port=6379     # Service name is the same as the Deployment name: orders-db
k -n s05-init get pod                                 # Init:Error / Init:CrashLoopBackOff
k -n s05-init logs <pod> -c migrate                   # can't create /work/migrated: nonexistent directory
k -n s05-init edit deploy orders
```
```yaml
      volumes:
      - name: work
        emptyDir: {}
      initContainers:
      - name: migrate
        ...
        volumeMounts: [{name: work, mountPath: /work}]
      containers:
      - name: orders
        ...
        volumeMounts: [{name: work, mountPath: /work}]
```
Init containers run **sequentially**; the next one doesn't start until the previous one finishes. Read their logs with `-c <init-container>`.
