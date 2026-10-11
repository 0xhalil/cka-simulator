Your team needs a second scheduler in the cluster. The default scheduler must keep working unchanged.

A ServiceAccount `custom-scheduler` with the required RBAC permissions already exists in namespace `s03-sched`.

1. Create a ConfigMap `custom-scheduler-config` in namespace `s03-sched` containing a `KubeSchedulerConfiguration` (API `kubescheduler.config.k8s.io/v1`) with:
   - leader election **disabled**
   - a profile with scheduler name `s03-custom-scheduler` (default plugins)
   - a second profile with scheduler name `s03-binpack-scheduler` that scores nodes with the `NodeResourcesFit` plugin using the scoring strategy `MostAllocated`
2. Create a Deployment `custom-scheduler` (1 replica) in namespace `s03-sched` that runs this scheduler:
   - image `registry.k8s.io/kube-scheduler:v1.37.1` (the same binary as the default scheduler), ServiceAccount `custom-scheduler`
   - the configuration is mounted from the ConfigMap and passed with `--config`
   - its Pod must run on the control plane node `cka-cp1`
3. Create Pod `custom-pod` (image `nginx:1.27-alpine`) in namespace `s03-sched` that is scheduled by `s03-custom-scheduler`, and Pod `binpack-pod` (image `nginx:1.27-alpine`) that is scheduled by `s03-binpack-scheduler`. Both must be `Running`.

Do not modify the default scheduler or any file in `/etc/kubernetes/manifests` on `cka-cp1`.
