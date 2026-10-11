There are two errors: **selector** (`tier: back-end` ≠ Pod label `tier: backend`) → no endpoints; once fixed, endpoints appear but **targetPort 80** is wrong (the container listens on 8080/`web`) → connection refused.

```bash
ssh cka-cp1
k -n s09-orbit get svc orbit-svc -o wide          # selector
k -n s09-orbit get pod --show-labels              # actual labels
k -n s09-orbit get endpointslice                   # no endpoints
k -n s09-orbit get deploy orbit-api -o yaml | grep -A2 ports   # containerPort 8080
k -n s09-orbit edit svc orbit-svc
#   selector: {app: orbit-api, tier: backend}
#   ports: [{name: http, port: 80, targetPort: 8080}]   # or targetPort: web
k -n s09-orbit get endpointslice
curl http://$(k -n s09-orbit get svc orbit-svc -o jsonpath='{.spec.clusterIP}')/
```

kube-proxy (iptables mode) writes the same rules on every node; rule comments contain `namespace/service:port`:
```bash
ssh cka-w1 "sudo iptables -t nat -S | grep 's09-orbit/orbit-svc'" > /opt/course/s09-orbit/iptables.txt
# -A KUBE-SERVICES -d <ClusterIP>/32 -p tcp ... -j KUBE-SVC-XXXX        <- ClusterIP match
# -A KUBE-SVC-XXXX ... --probability 0.5 -j KUBE-SEP-AAAA                <- load-balancing
# -A KUBE-SEP-AAAA -p tcp ... -j DNAT --to-destination 10.244.x.y:8080   <- endpoint
grep -- '-A KUBE-SERVICES' /opt/course/s09-orbit/iptables.txt | grep -o 'KUBE-SVC-[A-Z0-9]*' > /opt/course/s09-orbit/svc-chain.txt
```
Trap: if you save the rules before fixing, there are no DNAT lines (with no endpoints only a REJECT rule exists).
