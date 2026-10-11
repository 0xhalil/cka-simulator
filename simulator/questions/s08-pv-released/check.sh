REAL=$(on cka-w1 'cat /mnt/s08-archive/report-q3.txt')
check "PVC archive-restore is Bound to s08-archive-pv" '[ "$(jp pvc archive-restore -n s08-archive "{.status.phase}:{.spec.volumeName}")" = Bound:s08-archive-pv ]'
check "PV s08-archive-pv is Bound to s08-archive/archive-restore" '[ "$(jp pv s08-archive-pv "{.status.phase}:{.spec.claimRef.namespace}/{.spec.claimRef.name}")" = Bound:s08-archive/archive-restore ]'
check "Pod archive-reader is Running with the claim mounted at /archive" '[ "$(jp pod archive-reader -n s08-archive "{.status.phase}")" = Running ] && [ "$(jp pod archive-reader -n s08-archive "{.spec.volumes[?(@.persistentVolumeClaim.claimName==\"archive-restore\")].name}")" != "" ] && kubectl -n s08-archive exec archive-reader -- test -f /archive/report-q3.txt'
check "report-q3.txt copied to /opt/course/s08-archive/" '[ -n "$REAL" ] && [ "$(cat /opt/course/s08-archive/report-q3.txt)" = "$REAL" ]'
guard "PV was not recreated and keeps reclaim policy Retain" '[ "$(jp pv s08-archive-pv "{.metadata.uid}")" = "$(cat /var/lib/cka-sim/s08-archive-pv.uid)" ] && [ "$(jp pv s08-archive-pv "{.spec.persistentVolumeReclaimPolicy}")" = Retain ]'
