```bash
ssh cka-cp1
k get pc        # system-* classes (>1e9) are not user-defined; highest user-defined: team-critical=870000
k create priorityclass high-priority --value=869999 --description="high priority user workloads"
k -n priority patch deploy busybox-logger -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
k -n priority rollout status deploy busybox-logger
```
