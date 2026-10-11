D=/opt/course/s15-pv
kubectl get pv -l report=s15 --sort-by=.spec.capacity.storage -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,RECLAIM_POLICY:.spec.persistentVolumeReclaimPolicy > $D/pvs.txt
kubectl get pv -l report=s15 -o jsonpath='{.items[?(@.spec.persistentVolumeReclaimPolicy=="Retain")].metadata.name}' > $D/retain.txt
kubectl get pv -l report=s15 --sort-by=.spec.capacity.storage -o jsonpath='{.items[-1:].metadata.name}' > $D/largest.txt
cat $D/*
