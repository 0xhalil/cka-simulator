kubectl -n resources scale deploy web-portal --replicas=0
kubectl -n resources wait --for=delete pod -l app=web-portal --timeout=90s
# compute free resources on cka-w1 like a candidate would (describe node -> Allocated resources)
A_CPU=$(kubectl get node cka-w1 -o jsonpath='{.status.allocatable.cpu}'); A_CPU=${A_CPU%m}; [ ${#A_CPU} -le 2 ] && A_CPU=$((A_CPU*1000))
A_MEM=$(kubectl get node cka-w1 -o jsonpath='{.status.allocatable.memory}'); A_MEM=$(( ${A_MEM%Ki} / 1024 ))
USED=$(kubectl describe node cka-w1 | grep -A6 'Allocated resources' | awk '/cpu/{c=$2} /memory/{m=$2} END{print c" "m}')
U_CPU=$(echo $USED | awk '{print $1}' | sed 's/m//'); U_MEM=$(echo $USED | awk '{print $2}' | sed 's/Mi//')
CPU=$(( (A_CPU - U_CPU) * 85 / 100 / 3 ))m; MEM=$(( (A_MEM - U_MEM) * 85 / 100 / 3 ))Mi
echo "requests per pod: $CPU $MEM"
kubectl -n resources set resources deploy web-portal --requests=cpu=$CPU,memory=$MEM
kubectl -n resources scale deploy web-portal --replicas=3
kubectl -n resources rollout status deploy web-portal --timeout=120s
