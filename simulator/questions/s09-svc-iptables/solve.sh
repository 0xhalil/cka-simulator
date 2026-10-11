kubectl -n s09-orbit patch svc orbit-svc --type=json -p '[{"op":"replace","path":"/spec/selector/tier","value":"backend"},{"op":"replace","path":"/spec/ports/0/targetPort","value":8080}]'
sleep 5
ssh -o BatchMode=yes cka-w1 "iptables -t nat -S | grep 's09-orbit/orbit-svc'" </dev/null > /opt/course/s09-orbit/iptables.txt
grep -- '-A KUBE-SERVICES' /opt/course/s09-orbit/iptables.txt | grep -o 'KUBE-SVC-[A-Z0-9]*' | head -1 > /opt/course/s09-orbit/svc-chain.txt
cat /opt/course/s09-orbit/*.txt
