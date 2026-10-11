reset_ns storage-test
kubectl delete sc local-retain --ignore-not-found >/dev/null
kubectl patch sc local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' >/dev/null
