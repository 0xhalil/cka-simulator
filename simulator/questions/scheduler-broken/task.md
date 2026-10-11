In this cluster, the Pods of the Deployment `orbit` in namespace `ops` stay in `Pending` and newly created Pods are not scheduled anymore. A colleague recently "tuned" a control plane component on `cka-cp2`.

Fix the cluster so that Pods are scheduled again. The Deployment `orbit` must reach **3/3** available replicas. Do not modify the Deployment `orbit`.
