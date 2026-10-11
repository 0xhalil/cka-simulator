cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata: {name: custom-scheduler-config, namespace: s03-sched}
data:
  config.yaml: |
    apiVersion: kubescheduler.config.k8s.io/v1
    kind: KubeSchedulerConfiguration
    leaderElection:
      leaderElect: false
    profiles:
    - schedulerName: s03-custom-scheduler
    - schedulerName: s03-binpack-scheduler
      pluginConfig:
      - name: NodeResourcesFit
        args:
          scoringStrategy:
            type: MostAllocated
            resources:
            - {name: cpu, weight: 1}
            - {name: memory, weight: 1}
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
      tolerations:
      - {key: node-role.kubernetes.io/control-plane, operator: Exists, effect: NoSchedule}
      containers:
      - name: kube-scheduler
        image: registry.k8s.io/kube-scheduler:v1.37.1
        command: ["kube-scheduler", "--config=/etc/kubernetes/custom-scheduler/config.yaml", "-v=2"]
        resources: {requests: {cpu: 20m, memory: 32Mi}}
        livenessProbe:
          httpGet: {path: /healthz, port: 10259, scheme: HTTPS}
          initialDelaySeconds: 15
        volumeMounts: [{name: config, mountPath: /etc/kubernetes/custom-scheduler}]
      volumes:
      - name: config
        configMap: {name: custom-scheduler-config}
YAML
kubectl -n s03-sched rollout status deploy custom-scheduler --timeout=120s
cat <<'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata: {name: custom-pod, namespace: s03-sched}
spec:
  schedulerName: s03-custom-scheduler
  containers: [{name: nginx, image: nginx:1.27-alpine, resources: {requests: {cpu: 10m, memory: 16Mi}}}]
---
apiVersion: v1
kind: Pod
metadata: {name: binpack-pod, namespace: s03-sched}
spec:
  schedulerName: s03-binpack-scheduler
  containers: [{name: nginx, image: nginx:1.27-alpine, resources: {requests: {cpu: 10m, memory: 16Mi}}}]
YAML
kubectl -n s03-sched wait --for=condition=Ready pod/custom-pod pod/binpack-pod --timeout=90s
