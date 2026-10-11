C=/opt/course/s12-chart/inventory; T=/opt/course/s12-chart/inventory-0.2.0.tgz; NS=s12-inv
check "helm lint passes without errors" 'helm lint $C'
check "Chart.yaml: version 0.2.0, appVersion 1.27-alpine" '[ "$(helm show chart $C | python3 -c "import yaml,sys;d=yaml.safe_load(sys.stdin);print(d.get(\"version\"),d.get(\"appVersion\"))")" = "0.2.0 1.27-alpine" ]'
check "default values render image nginx:1.27-alpine (image.tag empty)" '[ -z "$(helm show values $C | python3 -c "import yaml,sys;print(yaml.safe_load(sys.stdin)[\"image\"].get(\"tag\") or \"\")")" ] && helm template x $C | grep -Eq "image: \"?nginx:1.27-alpine\"?$"'
check "package inventory-0.2.0.tgz exists and is valid" 'tar -tzf $T | grep -qx inventory/Chart.yaml && [ "$(helm show chart $T | grep "^version:")" = "version: 0.2.0" ] && helm lint $T'
check "release inventory deployed in s12-inv from chart inventory-0.2.0" 'helm -n $NS list -o json | jq -e ".[] | select(.name==\"inventory\" and .status==\"deployed\" and .chart==\"inventory-0.2.0\" and .app_version==\"1.27-alpine\")"'
check "2 Ready Pods running nginx:1.27-alpine" 'kubectl -n $NS rollout status deploy/inventory --timeout=120s && [ "$(jp -n $NS deploy inventory "{.status.readyReplicas}|{.spec.template.spec.containers[0].image}")" = "2|nginx:1.27-alpine" ]'
check "Service inventory answers on its ClusterIP" 'curl -s --max-time 5 http://$(jp -n $NS svc inventory "{.spec.clusterIP}"):80/ | grep -q "Welcome to nginx"'
