Namespace `s09-dns` runs the Deployment `catalog` (Service `catalog`) and the StatefulSet `ledger`. A test Pod `client` is running in namespace `s09-dns-client`.

1. The StatefulSet `ledger` refers to a governing Service that does not exist. Create it so that every `ledger` Pod gets its own stable DNS record (`<pod>.<service>.<namespace>.svc.cluster.local`). Don't modify the StatefulSet.
2. Run all of the following lookups with `nslookup` **from inside the Pod `client`** and save the complete output of each command on `cka-cp1`:

| File | Lookup |
|------|--------|
| `/opt/course/s09-dns/catalog-svc.txt` | the **fully qualified** DNS name of Service `catalog` |
| `/opt/course/s09-dns/ledger-1.txt` | the fully qualified DNS name of Pod `ledger-1` |
| `/opt/course/s09-dns/ledger-all.txt` | the fully qualified name of the governing Service from step 1 (it must return the IPs of **all** `ledger` Pods) |
| `/opt/course/s09-dns/catalog-pod.txt` | the fully qualified **Pod A record** (IP-based name) of the current `catalog` Pod |
