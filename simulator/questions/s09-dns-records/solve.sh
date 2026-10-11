cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata: {name: ledger-hl, namespace: s09-dns}
spec:
  clusterIP: None
  selector: {app: ledger}
  ports: [{port: 80}]
YAML
sleep 5
D=/opt/course/s09-dns
x() { kubectl -n s09-dns-client exec client -- nslookup "$1"; }
x catalog.s09-dns.svc.cluster.local > $D/catalog-svc.txt
x ledger-1.ledger-hl.s09-dns.svc.cluster.local > $D/ledger-1.txt
x ledger-hl.s09-dns.svc.cluster.local > $D/ledger-all.txt
IP=$(kubectl -n s09-dns get pod -l app=catalog -o jsonpath='{.items[0].status.podIP}')
x ${IP//./-}.s09-dns.pod.cluster.local > $D/catalog-pod.txt
cat $D/*.txt
