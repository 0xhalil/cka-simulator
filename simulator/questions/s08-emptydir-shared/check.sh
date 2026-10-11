V() { jp pod logger -n s08-vol "{.spec.volumes[?(@.name==\"$1\")].$2}"; }
M() { jp pod logger -n s08-vol "{.spec.containers[?(@.name==\"$1\")].volumeMounts[?(@.name==\"$2\")].$3}"; }
kubectl -n s08-vol wait --for=condition=Ready pod/logger --timeout=60s >/dev/null 2>&1
check "Pod logger is Running with containers writer and reader" '[ "$(jp pod logger -n s08-vol "{.status.phase}")" = Running ] && [ "$(jp pod logger -n s08-vol "{.spec.containers[*].name}" | tr " " "\n" | sort | tr "\n" " ")" = "reader writer " ]'
check "volume shared is an emptyDir with medium Memory and sizeLimit 32Mi" '[ "$(V shared emptyDir.medium):$(V shared emptyDir.sizeLimit)" = Memory:32Mi ]'
check "writer mounts shared at /var/log/app (tmpfs)" '[ "$(M writer shared mountPath)" = /var/log/app ] && kubectl -n s08-vol exec logger -c writer -- sh -c "grep \" /var/log/app \" /proc/mounts | grep -q tmpfs"'
check "reader mounts shared read-only at /input" '[ "$(M reader shared mountPath):$(M reader shared readOnly)" = /input:true ] && ! kubectl -n s08-vol exec logger -c reader -- touch /input/x'
check "volume node-name is hostPath /etc/hostname of type File, read-only in reader" '[ "$(V node-name hostPath.path):$(V node-name hostPath.type)" = /etc/hostname:File ] && [ "$(M reader node-name mountPath):$(M reader node-name readOnly)" = /node/hostname:true ]'
check "reader logs show the node name and entries from writer" 'n=$(jp pod logger -n s08-vol "{.spec.nodeName}"); for i in 1 2 3 4 5; do L=$(kubectl -n s08-vol logs logger -c reader); echo "$L" | grep -qx "node=$n" && echo "$L" | grep -q s08-entry && exit 0; sleep 2; done; exit 1'
check "manifest saved to /opt/course/s08-vol/logger.yaml" 'grep -q "medium: *Memory" /opt/course/s08-vol/logger.yaml && grep -q "hostPath" /opt/course/s08-vol/logger.yaml'
