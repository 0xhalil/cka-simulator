Create persistent storage for a small Redis cluster in namespace `s08-kv`.

1. Create a StorageClass `s08-fast` with provisioner `rancher.io/local-path`, reclaim policy `Delete`, volume binding mode `WaitForFirstConsumer` and **volume expansion allowed**. Do not make it the default StorageClass.
2. Create a headless Service `kv` (port `6379`) and a StatefulSet `kv` with **2** replicas using image `redis:7-alpine`, Pod label `app=kv`, command `redis-server --appendonly yes --dir /data`. Each replica must get its **own** PersistentVolumeClaim from a claim template named `data` (`ReadWriteOnce`, `64Mi`, StorageClass `s08-fast`) mounted at `/data`.
3. Once both replicas are ready, store the key `owner` with value `cka` in the Redis instance of Pod `kv-0` (`redis-cli set owner cka`). Then **delete the Pod `kv-0`** and verify that the value survives the Pod's recreation.
