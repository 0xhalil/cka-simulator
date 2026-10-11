Create a few reports about cluster1 using `kubectl` output options (JSONPath / custom columns). The files must contain only the requested output.

1. `/opt/course/s15-nodes/nodes.txt` — one line per node in the format
   ```
   <node-name><TAB><cpu capacity><TAB><InternalIP address>
   ```
   (separated by a real tab character, no header).

2. `/opt/course/s15-nodes/taints.txt` — a table with exactly the columns `NODE`, `TAINT_KEY`, `TAINT_EFFECT` (with that header line) listing every node and the key and effect of its taints.

3. `/opt/course/s15-nodes/images.txt` — every **distinct** container image used by the Pods (regular containers) in namespace `kube-system`, one per line, sorted alphabetically.
