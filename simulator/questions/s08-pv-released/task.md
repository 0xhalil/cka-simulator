The PersistentVolume `s08-archive-pv` (reclaim policy `Retain`) contains important archive data. It was used by a PVC in a namespace that has since been deleted.

The archive team now works in namespace `s08-archive`:

1. Create a PersistentVolumeClaim `archive-restore` in namespace `s08-archive` (access mode `ReadWriteOnce`, `300Mi`) that is **bound to `s08-archive-pv`**. The PV must **not** be deleted or recreated, and its data must be preserved. Keep the reclaim policy `Retain`.
2. Create a Pod `archive-reader` (image `busybox:1.36`, command `sleep 1d`) in namespace `s08-archive` that mounts the claim at `/archive`.
3. Copy the content of the file `report-q3.txt` stored on the volume into `/opt/course/s08-archive/report-q3.txt`.
