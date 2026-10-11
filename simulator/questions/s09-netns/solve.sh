ssh -o BatchMode=yes cka-w1 bash -s > /opt/course/s09-netns/tracer.env <<'SH'
ID=$(crictl pods --name tracer --namespace s09-netns -q | head -1)
NS=$(crictl inspectp $ID | jq -r '.info.runtimeSpec.linux.namespaces[] | select(.type=="network") | .path' | xargs basename)
echo NETNS=$NS
echo POD_IP=$(ip netns exec $NS ip -o -4 addr show dev eth0 | awk '{print $4}' | cut -d/ -f1)
echo POD_MTU=$(ip netns exec $NS ip -o link show dev eth0 | grep -o 'mtu [0-9]*' | cut -d' ' -f2)
echo POD_GATEWAY=$(ip netns exec $NS ip route | awk '/^default/{print $3}')
IDX=$(ip netns exec $NS ip -o link show dev eth0 | grep -o 'eth0@if[0-9]*' | sed 's/.*@if//')
echo HOST_VETH=$(ip -o link | awk -F': ' -v i=$IDX '$1==i{print $2}' | cut -d@ -f1)
SH
cat /opt/course/s09-netns/tracer.env
