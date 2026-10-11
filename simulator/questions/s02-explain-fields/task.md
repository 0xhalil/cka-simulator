Use `kubectl explain` to find the fields you need — no web search required.

**1.** In namespace `s02-explain` create a Pod `toolbox` with one container `shell` (image `busybox:1.36`, command `sleep 3600`) that meets **all** of the following:

- all containers of the Pod share a **single process namespace** (processes of other containers are visible)
- information about Services is **not** injected into the containers as environment variables
- the Pod is given only `5` seconds to shut down gracefully
- the container's `/etc/hosts` file contains an entry that resolves `legacy-db` and `legacy-db.internal` to `10.10.10.10`

**2.** Write into `/opt/course/s02-explain/fields.txt` the full field paths (starting with `spec.`) of the Deployment fields that control:

```
HISTORY=    # how many old ReplicaSets are kept to allow a rollback
READY=      # minimum seconds a new Pod must be ready without crashing to be counted as available
DEADLINE=   # maximum seconds for a Deployment to make progress before it is reported as failed
```
