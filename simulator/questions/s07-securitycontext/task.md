The Pod `secure-app` in namespace `s07-sec` is running with default (root) privileges. Its manifest is stored at `/opt/course/s07-sec/secure-app.yaml`.

Change the Pod (keep its name, namespace, images, commands and volumes) so that:

1. **All containers** of the Pod by default run with user ID `1000` and primary group ID `3000`, and files in mounted volumes belong to the supplemental group `2000`.
2. Container `app`:
   - has a **read-only root filesystem** (it may still write to its volume mounted at `/data`),
   - must not be able to gain more privileges than its parent process,
   - has **all** Linux capabilities dropped.
3. Container `clock` must run as **root** (user ID `0`) and additionally gets the Linux capability `SYS_TIME`.

Save your final manifest to `/opt/course/s07-sec/secure-app.yaml`. Make sure the Pod is running, then write the output of the command `id` executed inside container `app` into `/opt/course/s07-sec/id.txt`.
