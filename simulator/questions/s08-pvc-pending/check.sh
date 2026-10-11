P="pvc orders-data -n s08-shop"
check "PVC orders-data is Bound to s08-orders-pv" '[ "$(jp $P "{.status.phase}:{.spec.volumeName}")" = Bound:s08-orders-pv ]'
check "PVC requests 200Mi with ReadWriteOnce and class s08-manual" '[ "$(jp $P "{.spec.resources.requests.storage}:{.spec.accessModes[*]}:{.spec.storageClassName}")" = 200Mi:ReadWriteOnce:s08-manual ]'
check "Deployment orders is available and uses PVC orders-data" '[ "$(jp deploy orders -n s08-shop "{.spec.template.spec.volumes[*].persistentVolumeClaim.claimName}")" = orders-data ] && kubectl -n s08-shop rollout status deploy/orders --timeout=150s'
check "orders serves the data from the PV" 'kubectl -n s08-shop exec deploy/orders -- wget -qO- -T 4 http://localhost/ </dev/null | grep -q "4711 open"'
guard "PersistentVolumes unchanged" '[ "$(jp pv s08-orders-pv "{.spec.capacity.storage}:{.spec.accessModes[*]}:{.spec.storageClassName}:{.spec.persistentVolumeReclaimPolicy}")" = 200Mi:ReadWriteOnce:s08-manual:Retain ] && [ "$(jp pv s08-orders-archive "{.status.phase}:{.spec.capacity.storage}")" = Available:100Mi ]'
