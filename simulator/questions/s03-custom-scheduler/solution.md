An additional scheduler = the same `kube-scheduler` binary + a config with a different `schedulerName`. One config can contain multiple **profiles**; each profile is a separate scheduler name (lecture: "Configuring Scheduler Profiles"). Doc: "Configure Multiple Schedulers" + "Scheduler Configuration".

```yaml
apiVersion: v1
kind: ConfigMap
metadata: {name: custom-scheduler-config, namespace: s03-sched}
data:
  config.yaml: |
    apiVersion: kubescheduler.config.k8s.io/v1
    kind: KubeSchedulerConfiguration
    leaderElection:
      leaderElect: false              # single replica; if true it can't acquire the lease and never schedules
    profiles:
    - schedulerName: s03-custom-scheduler
    - schedulerName: s03-binpack-scheduler
      pluginConfig:
      - name: NodeResourcesFit
        args:
          scoringStrategy:
            type: MostAllocated
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: custom-scheduler, namespace: s03-sched}
spec:
  replicas: 1
  selector: {matchLabels: {app: custom-scheduler}}
  template:
    metadata: {labels: {app: custom-scheduler}}
    spec:
      serviceAccountName: custom-scheduler
      nodeSelector: {kubernetes.io/hostname: cka-cp1}
      tolerations:                     # required because of the CP taint
      - {key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}
      containers:
      - name: kube-scheduler
        image: registry.k8s.io/kube-scheduler:v1.37.1
        command: ["kube-scheduler", "--config=/etc/kubernetes/custom-scheduler/config.yaml"]
        volumeMounts: [{name: config, mountPath: /etc/kubernetes/custom-scheduler}]
      volumes:
      - name: config
        configMap: {name: custom-scheduler-config}
```
In the Pods, just `spec.schedulerName: s03-custom-scheduler` / `s03-binpack-scheduler`.
```bash
ssh cka-cp1
k -n s03-sched logs deploy/custom-scheduler          # "Successfully bound pod to node"
k -n s03-sched get events -o wide | grep Scheduled    # scheduler name in the SOURCE column
```
Traps: if `schedulerName` doesn't match a profile, the pod stays Pending forever (the default scheduler won't pick it up). The `extension-apiserver-authentication` configmap warning is harmless.
