kubectl create priorityclass high-priority --value=869999 --description="high priority user workloads"
kubectl -n priority patch deploy busybox-logger -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
kubectl -n priority rollout status deploy busybox-logger
