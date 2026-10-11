```bash
ssh cka-cp1
k describe node cka-w1 | grep -A12 'Allocated resources'      # Allocatable - current requests
k -n resources scale deploy web-portal --replicas=0
```
Example (node with 2 CPU / ~1.9Gi allocatable, other pods requesting ~350m / ~300Mi):
free ≈ 1650m / 1600Mi → leave some overhead and /3 ≈ **450m / 450Mi** per pod.

```bash
k -n resources set resources deploy web-portal --requests=cpu=450m,memory=450Mi
k -n resources scale deploy web-portal --replicas=3
k -n resources get pod -o wide
```
Without `-c`, `kubectl set resources` applies to **all** containers, including init containers (a `-c a,b` list is not supported). Since init containers run sequentially, the pod's effective request is `max(init, sum(containers))` — so giving them the same value makes sense.
