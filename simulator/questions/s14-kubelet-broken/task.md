Node `cka-w2` went `NotReady` after a colleague applied some "systemd tuning" to the kubelet on that node.

Fix the node so that it is `Ready` again. Requirements:

- The kubelet must run the binary installed by the Kubernetes package (`/usr/bin/kubelet`).
- The kubelet must talk to the API server endpoint of this cluster `https://192.168.104.1:6443`.
- The kubelet service must be enabled.

You can access the worker with `ssh cka-w2` from `cka-cp2`.
