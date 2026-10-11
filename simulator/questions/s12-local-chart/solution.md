Three errors: `version` missing in `Chart.yaml`, unclosed `{{ ... }` in `templates/service.yaml`, image name typo in `values.yaml` (`ngnix`) — `helm lint` doesn't catch the last one; the Pods end up in ImagePullBackOff.

```bash
ssh cka-cp1
cd /opt/course/s12-chart
helm lint inventory                     # [ERROR] Chart.yaml: version is required ... / parse error in service.yaml
vi inventory/Chart.yaml                 # version: 0.2.0   appVersion: "1.27-alpine"
vi inventory/templates/service.yaml     # - port: {{ .Values.service.port }}
vi inventory/values.yaml                # image.repository: nginx   (tag: "" -> appVersion is used)
helm lint inventory
helm template x inventory | grep image: # image: "nginx:1.27-alpine"
helm package inventory                  # -> inventory-0.2.0.tgz (name from Chart.yaml)
helm install inventory ./inventory-0.2.0.tgz -n s12-inv --create-namespace --set replicaCount=2
k -n s12-inv get pods,svc
curl http://<ClusterIP>/
```
Note: the line `image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"` in `deployment.yaml` uses appVersion if the tag is empty. appVersion should be quoted (`1.27-alpine` is a string).
