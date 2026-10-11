C=/opt/course/s12-pull/podinfo; NS=s12-docs
repo_ok() { for u in root candidate; do sudo -u $u -H helm repo list -o json 2>/dev/null | jq -e --arg n "$1" --arg u "$2" '.[] | select(.name==$n and (.url|rtrimstr("/"))==$u)' && return 0; done; return 1; }
yv() { python3 -c "import yaml,sys,json;print(json.dumps(yaml.safe_load(open(sys.argv[1]))))" "$1" 2>/dev/null; }
IP=$(jp node cka-w1 '{.status.addresses[?(@.type=="InternalIP")].address}')
check "repo s12-pi added" 'repo_ok s12-pi https://stefanprodan.github.io/podinfo'
check "chart podinfo 6.13.0 extracted to /opt/course/s12-pull/podinfo" '[ "$(yv $C/Chart.yaml | jq -r ".name+\"-\"+.version")" = podinfo-6.13.0 ] && [ -d $C/templates ]'
check "local values.yaml: replicaCount 2, NodePort 30913, ui.message" 'yv $C/values.yaml | jq -e ".replicaCount==2 and .service.type==\"NodePort\" and .service.nodePort==30913 and .ui.message==\"docs portal\""'
check "release docs deployed from podinfo-6.13.0 without user-supplied values" 'helm -n $NS list -o json | jq -e ".[] | select(.name==\"docs\" and .status==\"deployed\" and .chart==\"podinfo-6.13.0\")" && [ "$(helm -n $NS get values docs -o json | jq -c ". // {}")" = "{}" ]'
check "2 Ready Pods and Service NodePort 30913 answers with the message" 'kubectl -n $NS rollout status deploy/docs-podinfo --timeout=120s && [ "$(jp -n $NS deploy docs-podinfo "{.status.readyReplicas}")" = 2 ] && [ "$(jp -n $NS svc docs-podinfo "{.spec.type}:{.spec.ports[?(@.name==\"http\")].nodePort}")" = NodePort:30913 ] && curl -s --max-time 5 http://$IP:30913/ | grep -q "\"message\": *\"docs portal\""'
check "docs-manifest.yaml equals helm get manifest docs" 'test -s /opt/course/s12-pull/docs-manifest.yaml && grep -q docs-podinfo /opt/course/s12-pull/docs-manifest.yaml && diff <(helm -n $NS get manifest docs | grep -v "^\s*$") <(grep -v "^\s*$" /opt/course/s12-pull/docs-manifest.yaml)'
