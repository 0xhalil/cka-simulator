course_dir s12-chart
helm -n s12-inv uninstall inventory >/dev/null 2>&1 || true
kubectl delete ns s12-inv --ignore-not-found --wait=true --timeout=120s >/dev/null 2>&1
cd /opt/course/s12-chart && helm create inventory >/dev/null
C=/opt/course/s12-chart/inventory
sed -i '/^version:/d' $C/Chart.yaml
sed -i 's/- port: {{ .Values.service.port }}/- port: {{ .Values.service.port }/' $C/templates/service.yaml
sed -i 's/^  repository: nginx$/  repository: ngnix/' $C/values.yaml
chown -R candidate: /opt/course
