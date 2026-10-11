helm repo add s12-pi https://stefanprodan.github.io/podinfo
helm repo update s12-pi
cd /opt/course/s12-pull && helm pull s12-pi/podinfo --version 6.13.0 --untar
V=/opt/course/s12-pull/podinfo/values.yaml
sed -i 's/^replicaCount: 1/replicaCount: 2/' $V
python3 - $V <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
s=re.sub(r'(\nservice:\n(?:.*\n)*?  type: )ClusterIP', r'\1NodePort', s, count=1)
s=re.sub(r'(\n  nodePort: )31198', r'\g<1>30913', s, count=1)
s=re.sub(r'(\nui:\n(?:.*\n)*?  message: )""', r'\1"docs portal"', s, count=1)
open(p,'w').write(s)
PY
helm install docs /opt/course/s12-pull/podinfo -n s12-docs --create-namespace --wait --timeout 3m
helm -n s12-docs get manifest docs > /opt/course/s12-pull/docs-manifest.yaml
