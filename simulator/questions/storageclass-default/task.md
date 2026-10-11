1. Create a new StorageClass named `local-retain` with:
   - provisioner `rancher.io/local-path`
   - reclaim policy `Retain`
   - volume binding mode `WaitForFirstConsumer`
2. Make `local-retain` the **only default** StorageClass in the cluster. Do **not** delete or otherwise modify the existing StorageClass `local-path` besides its default flag.
3. Create a PersistentVolumeClaim `data-claim` in namespace `storage-test` requesting `100Mi`, access mode `ReadWriteOnce`, **without** specifying a storageClassName, and a Pod `data-pod` (image `busybox:1.36`, command `sleep 1d`) that mounts it at `/data`.

The PVC must be bound by the new StorageClass.
