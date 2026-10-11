D=/opt/course/s04-top
for i in $(seq 40); do
  [ "$(kubectl -n s04-top top pod --no-headers 2>/dev/null | wc -l)" = 4 ] && break; sleep 5
done
sleep 20   # let the metrics settle (dd + cpu loop)
kubectl -n s04-top top pod
kubectl -n s04-top top pod --sort-by=cpu --no-headers | head -1 | awk '{print $1}' > $D/cpu.txt
kubectl -n s04-top top pod --sort-by=memory --no-headers | head -1 | awk '{print $1}' > $D/mem.txt
echo 'kubectl top node --sort-by=memory' > $D/nodes.sh
echo 'kubectl -n s04-top top pod --containers' > $D/containers.sh
cat $D/cpu.txt $D/mem.txt
