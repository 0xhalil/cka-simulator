A number of PersistentVolumes in cluster1 carry the label `report=s15`. Only consider these PVs.

1. Write a table into `/opt/course/s15-pv/pvs.txt` with exactly the columns `NAME`, `CAPACITY`, `RECLAIM_POLICY` (header included), **sorted by capacity, smallest first**. Use `kubectl` to produce it.
2. Write the names of the PVs (with label `report=s15`) whose reclaim policy is `Retain` into `/opt/course/s15-pv/retain.txt`, space separated on a single line, using a JSONPath filter expression.
3. Write the name of the PV (with label `report=s15`) with the **largest** capacity into `/opt/course/s15-pv/largest.txt`.
