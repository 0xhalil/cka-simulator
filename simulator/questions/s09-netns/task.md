Pod `tracer` in namespace `s09-netns` runs on node `cka-w1`. Investigate how the CNI plugin wired it into the node's network and write your findings to `/opt/course/s09-netns/tracer.env` on `cka-cp1`, one `KEY=value` per line (no spaces, no quotes):

| Key | Value |
|-----|-------|
| `NETNS` | name of the Pod's network namespace as listed by `ip netns` on `cka-w1` |
| `POD_IP` | IPv4 address of interface `eth0` inside that network namespace |
| `POD_MTU` | MTU of `eth0` inside that network namespace |
| `POD_GATEWAY` | default gateway inside that network namespace |
| `HOST_VETH` | name of the **host-side** interface (on `cka-w1`) that is the peer of the Pod's `eth0` |

Find the values from the node itself (container runtime and Linux network tools). Don't delete or restart the Pod.
