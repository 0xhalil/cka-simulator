The Metrics Server is installed in cluster1. The team running the Pods in namespace `s04-top` complains about one Pod eating CPU and another one eating memory.

1. Write the name of the Pod in namespace `s04-top` with the **highest CPU usage** into `/opt/course/s04-top/cpu.txt`.
2. Write the name of the Pod in namespace `s04-top` with the **highest memory usage** into `/opt/course/s04-top/mem.txt`.
3. Write a command into `/opt/course/s04-top/nodes.sh` that shows the current CPU and memory usage of all **nodes**, sorted by **memory** usage.
4. Write a command into `/opt/course/s04-top/containers.sh` that shows the CPU and memory usage of every **container** (not only every Pod) in namespace `s04-top`.

Note: freshly started Pods may need a minute until metrics are available.
