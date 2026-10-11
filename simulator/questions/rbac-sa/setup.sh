course_dir rbac
reset_ns cicd staging
kubectl delete clusterrole pipeline-deployer --ignore-not-found >/dev/null
kubectl delete clusterrolebinding -l cka-sim=rbac --ignore-not-found >/dev/null
kubectl -n cicd create deploy runner --image=busybox:1.36 -- sleep 1d >/dev/null
