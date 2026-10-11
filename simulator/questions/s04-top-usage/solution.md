`kubectl top` shows **point-in-time** (in-memory) values from the Metrics Server; the first measurement for new Pods can take ~1 minute.

```bash
ssh cka-cp1
k -n s04-top top pod --sort-by=cpu
k -n s04-top top pod --sort-by=memory
k -n s04-top top pod --sort-by=cpu --no-headers | head -1 | awk '{print $1}' > /opt/course/s04-top/cpu.txt
k -n s04-top top pod --sort-by=memory --no-headers | head -1 | awk '{print $1}' > /opt/course/s04-top/mem.txt

echo 'kubectl top node --sort-by=memory' > /opt/course/s04-top/nodes.sh
echo 'kubectl -n s04-top top pod --containers' > /opt/course/s04-top/containers.sh
bash /opt/course/s04-top/nodes.sh; bash /opt/course/s04-top/containers.sh
```
Note: the memory-hungry Pod writes data to a `medium: Memory` emptyDir (tmpfs) — tmpfs pages are counted against the container's memory cgroup. Without `--containers` you see one line per Pod (sum of its containers).
