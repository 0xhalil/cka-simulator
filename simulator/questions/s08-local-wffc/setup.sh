course_dir s08-local
kubectl delete ns s08-local --ignore-not-found --wait=true --timeout=120s >/dev/null 2>&1
kubectl delete pv s08-local-pv --ignore-not-found --wait=true >/dev/null 2>&1
kubectl delete sc s08-local --ignore-not-found >/dev/null
on cka-w1 'rm -rf /mnt/s08-local; mkdir -p /mnt/s08-local; chmod 777 /mnt/s08-local'
kubectl create ns s08-local >/dev/null
