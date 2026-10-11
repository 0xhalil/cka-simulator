kubectl -n s03-labels get pod -l env=prod,tier=frontend -o name | cut -d/ -f2 > /opt/course/s03-labels/prod-frontend.txt
kubectl -n s03-labels get pod -l 'bu=finance,env!=prod' --no-headers | wc -l > /opt/course/s03-labels/finance-nonprod.txt
kubectl -n s03-labels label pod -l 'tier=backend,env!=prod' track=canary
kubectl -n s03-labels patch svc shop-frontend --type=json -p '[{"op":"replace","path":"/spec/selector","value":{"app":"shop","tier":"frontend","env":"prod"}}]'
