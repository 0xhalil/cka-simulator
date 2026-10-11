The control plane of this cluster has already been upgraded, but worker node `cka-w2` still runs an older Kubernetes version.

Upgrade `cka-w2` so that **kubeadm, kubelet and kubectl** match the exact version of the control plane node `cka-cp2`.

- Drain the node before upgrading the kubelet and make it schedulable again afterwards.
- Use the `pkgs.k8s.io` package repository that is already configured on the node (you will need to switch it to the right minor version).

You can access the worker with `ssh cka-w2` from `cka-cp2`.
