C=/opt/course/s12-chart/inventory
sed -i 's/^appVersion:.*/appVersion: "1.27-alpine"/' $C/Chart.yaml
grep -q '^version:' $C/Chart.yaml || echo 'version: 0.2.0' >> $C/Chart.yaml
sed -i 's/{{ .Values.service.port }$/{{ .Values.service.port }}/' $C/templates/service.yaml
sed -i 's/^  repository: ngnix$/  repository: nginx/' $C/values.yaml
helm lint $C
cd /opt/course/s12-chart && helm package inventory
helm install inventory /opt/course/s12-chart/inventory-0.2.0.tgz -n s12-inv --create-namespace --set replicaCount=2 --wait --timeout 3m
