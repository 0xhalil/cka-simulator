F=/opt/course/s09-netns/tracer.env
val() { grep -E "^$1=" $F 2>/dev/null | tail -1 | cut -d= -f2- | tr -d ' "\r'"'"; }
NETNS=$(on cka-w1 'ID=$(crictl pods --name tracer --namespace s09-netns --state ready -q | head -1); crictl inspectp $ID | jq -r ".info.runtimeSpec.linux.namespaces[] | select(.type==\"network\") | .path"' | xargs -r basename)
ex() { on cka-w1 "ip netns exec $NETNS $1"; }
PIP=$(ex "ip -o -4 addr show dev eth0" | awk '{print $4}' | cut -d/ -f1)
MTU=$(ex "cat /sys/class/net/eth0/mtu")
GW=$(ex "ip route show default" | awk '{print $3}')
IDX=$(ex "cat /sys/class/net/eth0/iflink")
VETH=$(on cka-w1 "ip -o link" | awk -F': ' -v i=$IDX '$1==i{print $2}' | cut -d@ -f1)
guard "Pod tracer was not recreated" '[ "$(jp -n s09-netns pod tracer "{.status.containerStatuses[0].restartCount}")" = 0 ] && [ -n "$NETNS" ]'
check "NETNS is the Pod sandbox network namespace" '[ "$(val NETNS)" = "$NETNS" ]'
check "POD_IP is the eth0 address inside the netns" '[ -n "$PIP" ] && [ "$(val POD_IP)" = "$PIP" ]'
check "POD_MTU is the eth0 MTU inside the netns" '[ -n "$MTU" ] && [ "$(val POD_MTU)" = "$MTU" ]'
check "POD_GATEWAY is the default gateway inside the netns" '[ -n "$GW" ] && [ "$(val POD_GATEWAY)" = "$GW" ]'
check "HOST_VETH is the host-side peer of eth0" '[ -n "$VETH" ] && [ "$(val HOST_VETH)" = "$VETH" ]'
