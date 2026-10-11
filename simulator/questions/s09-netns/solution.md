Every pod sandbox (pause container) has its own network namespace; the CNI (Calico) creates a **veth pair**: one end is `eth0` in the pod netns, the other end is `cali...` on the host.

```bash
ssh cka-cp1
k -n s09-netns get pod tracer -o wide             # node: cka-w1, IP
ssh cka-w1
sudo -i
crictl pods --name tracer --namespace s09-netns   # POD ID
crictl inspectp <POD-ID> | jq '.info.runtimeSpec.linux.namespaces[] | select(.type=="network")'
#   "path": "/var/run/netns/cni-1234..."          -> NETNS=cni-1234...
ip netns list | grep cni-1234
ip netns exec cni-1234... ip addr show eth0       # inet 10.244.x.y/32, mtu 1450 (VXLAN overhead)
#   2: eth0@if120: ...                            -> peer ifindex 120
ip netns exec cni-1234... ip route                # default via 169.254.1.1 (Calico's fake gateway)
ip -o link | grep '^120:'                         # 120: cali1a2b3c4d5e6@if2 -> HOST_VETH=cali1a2b3c4d5e6
ip route | grep 10.244.x.y                        # same interface: 10.244.x.y dev caliXXXX scope link
```
`/opt/course/s09-netns/tracer.env` (on cka-cp1):
```
NETNS=cni-...
POD_IP=10.244.x.y
POD_MTU=1450
POD_GATEWAY=169.254.1.1
HOST_VETH=cali...
```
Trap: the number in `@if120` is the peer's **ifindex** (not a name); find the host-side name in the `ip link` output. Don't include the `@if2` suffix in the `HOST_VETH` value.
