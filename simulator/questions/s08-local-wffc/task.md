A latency-sensitive app needs the local disk of node `cka-w1`. The directory `/mnt/s08-local` already exists on `cka-w1`.

1. Create a StorageClass `s08-local` that does **not** provision volumes dynamically and delays volume binding until a Pod using the claim is scheduled.
2. Create a PersistentVolume `s08-local-pv` of type **`local`** (not `hostPath`) for path `/mnt/s08-local` on node `cka-w1` with capacity `128Mi`, access mode `ReadWriteOnce`, reclaim policy `Retain` and StorageClass `s08-local`.
3. In namespace `s08-local` create a PersistentVolumeClaim `local-claim` requesting `128Mi` (`ReadWriteOnce`) from StorageClass `s08-local`. Right after creating it, write its **status phase** (only the phase, e.g. `Bound`) to `/opt/course/s08-local/pvc-phase.txt`.
4. Create a Pod `local-writer` (image `busybox:1.36`) in namespace `s08-local` that mounts the claim at `/data` and runs `sh -c 'echo "written by $(hostname)" > /data/hello.txt; sleep 1d'`. **Do not** use `nodeName` or `nodeSelector` in the Pod.
