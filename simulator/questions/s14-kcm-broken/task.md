In namespace `kcm-lab` on cluster `cka-cp2`, Deployment `pulse` was created a while ago but it has **no Pods** - not even a ReplicaSet. Also, scaling Deployment `beacon` in the same namespace to **3** replicas "did not do anything".

1. Find and fix the root cause in the control plane on `cka-cp2`.
2. Ensure Deployment `pulse` has **2/2** and Deployment `beacon` has **3/3** available replicas.

Do not delete or modify Deployment `pulse`.
