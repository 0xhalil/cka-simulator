```bash
ssh cka-cp1
helm repo add s12-pi https://stefanprodan.github.io/podinfo
helm repo update
helm search repo s12-pi/podinfo --versions | grep 6.13.0
cd /opt/course/s12-pull
helm pull s12-pi/podinfo --version 6.13.0 --untar      # -> ./podinfo/ (a directory instead of a tgz)
vi podinfo/values.yaml
#   replicaCount: 2
#   ui:
#     message: "docs portal"
#   service:
#     type: NodePort
#     nodePort: 30913
helm install docs ./podinfo -n s12-docs --create-namespace
helm -n s12-docs get values docs          # USER-SUPPLIED VALUES: null  (values are inside the chart)
helm -n s12-docs get manifest docs > /opt/course/s12-pull/docs-manifest.yaml
curl http://<nodeIP>:30913/
```
Note: without `--untar`, `podinfo-6.13.0.tgz` is downloaded. `--untardir` picks the target directory. `helm get manifest` is the rendered YAML stored in Helm's release record (not `helm template` output).
