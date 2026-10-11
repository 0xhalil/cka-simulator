```bash
ssh cka-cp1
k -n autoscale autoscale deploy apache-server --name apache-server --cpu-percent=50 --min=1 --max=4 $do > hpa.yaml   # skeleton (or copy from the docs)
```
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: {name: apache-server, namespace: autoscale}
spec:
  scaleTargetRef: {apiVersion: apps/v1, kind: Deployment, name: apache-server}
  minReplicas: 1
  maxReplicas: 4
  metrics:
  - type: Resource
    resource: {name: cpu, target: {type: Utilization, averageUtilization: 50}}
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30
```
`kubectl autoscale` does not support the behavior field — you have to add it to the YAML.
