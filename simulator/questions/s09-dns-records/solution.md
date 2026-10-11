The StatefulSet says `spec.serviceName: ledger-hl` but no such Service exists → no per-pod DNS records are created. Per-pod records only come with a **headless** (`clusterIP: None`) governing Service.

```yaml
apiVersion: v1
kind: Service
metadata: {name: ledger-hl, namespace: s09-dns}
spec:
  clusterIP: None
  selector: {app: ledger}
  ports: [{port: 80}]
```

```bash
ssh cka-cp1
k -n s09-dns get sts ledger -o jsonpath='{.spec.serviceName}'
k apply -f ledger-hl.yaml
x() { k -n s09-dns-client exec client -- nslookup "$1"; }
x catalog.s09-dns.svc.cluster.local              > /opt/course/s09-dns/catalog-svc.txt   # <svc>.<ns>.svc.cluster.local
x ledger-1.ledger-hl.s09-dns.svc.cluster.local   > /opt/course/s09-dns/ledger-1.txt      # <pod>.<headless-svc>.<ns>.svc...
x ledger-hl.s09-dns.svc.cluster.local            > /opt/course/s09-dns/ledger-all.txt    # headless: returns all pod IPs
k -n s09-dns get pod -l app=catalog -o wide      # IP e.g. 10.244.95.12
x 10-244-95-12.s09-dns.pod.cluster.local         > /opt/course/s09-dns/catalog-pod.txt   # dashes instead of dots, "pod" subdomain
```
Trap: `client` is in another namespace → the short name `catalog` doesn't resolve (the `/etc/resolv.conf` search list starts with `s09-dns-client.svc.cluster.local`). A normal (ClusterIP) Service returns a single ClusterIP, a headless Service returns the pod IPs. Pod A records also exist for Deployment pods, but there are no hostname-based records.
