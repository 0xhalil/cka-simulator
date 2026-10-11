Create a Pod `logger` in namespace `s08-vol` (image `busybox:1.36` for all containers) with two containers that share a volume:

- Volume `shared`: an `emptyDir` that is backed by **memory (tmpfs)** and limited to **32Mi**.
- Volume `node-name`: the file `/etc/hostname` of the node the Pod runs on (it must be a **file**, not a directory).
- Container `writer` mounts `shared` at `/var/log/app` and runs
  `sh -c 'while true; do echo "$(date) s08-entry" >> /var/log/app/app.log; sleep 2; done'`
- Container `reader` mounts `shared` **read-only** at `/input`, mounts `node-name` **read-only** at `/node/hostname` and runs
  `sh -c 'echo "node=$(cat /node/hostname)"; tail -f /input/app.log'`

Write the Pod manifest to `/opt/course/s08-vol/logger.yaml` before creating it. Ensure the Pod is running and the `reader` container's logs show the entries written by `writer`.
