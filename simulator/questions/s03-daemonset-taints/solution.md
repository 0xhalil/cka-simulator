```bash
ssh cka-cp1
k describe node cka-cp1 | grep -A2 Taints      # node-role.kubernetes.io/control-plane:NoSchedule
echo node-role.kubernetes.io/control-plane:NoSchedule > /opt/course/s03-ds/cp-taints.txt
k -n s03-ds edit ds node-exporter-lite          # the old "master" taint key no longer exists -> control-plane
```
```yaml
      tolerations:
      - {key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}
```
There is no `kubectl create daemonset`: `k create deploy log-shipper --image=busybox:1.36 $do > ds.yaml`, then change to `kind: DaemonSet` and delete `replicas`/`strategy`/`status`:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata: {name: log-shipper, namespace: s03-ds}
spec:
  selector: {matchLabels: {app: log-shipper}}
  template:
    metadata: {labels: {app: log-shipper}}
    spec:
      nodeSelector: {node-role.kubernetes.io/control-plane: ""}   # attraction -> CP only
      tolerations:                                                # permission -> despite the taint
      - {key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}
      containers:
      - name: shipper
        image: busybox:1.36
        command: ["sh", "-c", "tail -F /host/log/syslog"]
        resources: {requests: {cpu: 5m, memory: 16Mi}}
        volumeMounts: [{name: varlog, mountPath: /host/log, readOnly: true}]
      volumes:
      - {name: varlog, hostPath: {path: /var/log}}
```
Lecture: "Taints & Tolerations vs Node Affinity" — a toleration does **not attract** a pod to a node, it only permits it. "CP only" requires a toleration **+** nodeSelector/affinity.
