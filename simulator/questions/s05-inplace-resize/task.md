The Pod `metrics-agent` in namespace `s05-resize` is a long-running singleton that must **not** be recreated.

1. Increase its CPU **request** to `100m` and its CPU **limit** to `200m` **in place**. The container must not restart for this change.
2. Increase its memory **limit** to `128Mi` **in place** (the memory request stays `32Mi`). The Pod's resize policy decides whether the container restarts for this change.
3. Write the container's restart count after both changes into `/opt/course/s05-resize/restarts.txt`.

The Pod must keep its UID. The new resources must be applied by the kubelet (visible in the container status), not only requested.
