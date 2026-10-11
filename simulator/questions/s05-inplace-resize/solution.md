A Pod's resources can't be changed with a plain `kubectl edit pod` (Forbidden). In-place resize is done via the **`resize` subresource**:

```bash
ssh cka-cp1
k -n s05-resize get pod metrics-agent -o yaml | grep -A4 resizePolicy    # cpu: NotRequired, memory: RestartContainer
k -n s05-resize patch pod metrics-agent --subresource resize --patch \
  '{"spec":{"containers":[{"name":"agent","resources":{"requests":{"cpu":"100m"},"limits":{"cpu":"200m"}}}]}}'
k -n s05-resize patch pod metrics-agent --subresource resize --patch \
  '{"spec":{"containers":[{"name":"agent","resources":{"limits":{"memory":"128Mi"}}}]}}'
# alternative: k -n s05-resize edit pod metrics-agent --subresource resize
k -n s05-resize get pod metrics-agent -o jsonpath='{.status.containerStatuses[0].resources}{"\n"}{.status.containerStatuses[0].restartCount}'
```
The CPU change is `NotRequired`, so no restart; memory is `RestartContainer` → the container restarts **once**, the Pod (UID) stays the same.
`status.containerStatuses[].resources` shows the values the kubelet actually applied.
