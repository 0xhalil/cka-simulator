kubectl delete clusterrolebinding s03-custom-scheduler s03-custom-scheduler-volume --ignore-not-found >/dev/null
kubectl delete clusterrole s03-custom-scheduler --ignore-not-found >/dev/null
reset_ns s03-sched
course_dir s03-sched
# like system:kube-scheduler but WITHOUT any lease permissions (so it can never take over the default scheduler's lease)
kubectl get clusterrole system:kube-scheduler -o json | jq '{apiVersion, kind, metadata: {name: "s03-custom-scheduler"},
  rules: [.rules[] | select((.resources | index("leases") or index("leasecandidates")) | not)]}' | kubectl apply -f -
kubectl -n s03-sched create serviceaccount custom-scheduler
kubectl create clusterrolebinding s03-custom-scheduler --clusterrole=s03-custom-scheduler --serviceaccount=s03-sched:custom-scheduler
kubectl create clusterrolebinding s03-custom-scheduler-volume --clusterrole=system:volume-scheduler --serviceaccount=s03-sched:custom-scheduler
