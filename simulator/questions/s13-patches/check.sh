O=/opt/course/s13-patch/overlays/staging; NS=s13-patch
K=$(python3 -c "import yaml,sys,json;print(json.dumps(yaml.safe_load(open(sys.argv[1]))))" $O/kustomization.yaml 2>/dev/null)
envv() { kubectl -n $NS get deploy ledger -o json | jq -r --arg n "$1" '.spec.template.spec.containers[0].env[] | select(.name==$n) | .value'; }
ann() { jp -n $NS deploy $1 '{.spec.template.metadata.annotations.backup\.s13/enabled}'; }
guard "base unchanged" 'cd /opt/course/s13-patch/base && sha256sum -c --quiet /root/.s13-patch.sha'
check "overlay uses the base, namespace s13-patch and builds" 'jq -e ".namespace==\"s13-patch\" and (.resources|any(test(\"base\")))" <<<"$K" && kubectl kustomize $O >/dev/null'
check "inline JSON6902 patch on Deployment ledger (replace + remove ops)" 'jq -e "[.patches[]? | select(.target.name==\"ledger\") | .patch // empty | test(\"op\") ] | any" <<<"$K"'
check "ledger runs 2 replicas without livenessProbe" '[ "$(jp -n $NS deploy ledger "{.spec.replicas}")" = 2 ] && [ -z "$(jp -n $NS deploy ledger "{.spec.template.spec.containers[0].livenessProbe}")" ] && kubectl -n $NS get deploy ledger'
check "strategic merge patch file ledger-env.yaml referenced by path" 'jq -e "[.patches[]?.path // empty, .patchesStrategicMerge[]? | sub(\"^\\\\./\";\"\")] | index(\"ledger-env.yaml\")" <<<"$K" && grep -q "REGION" $O/ledger-env.yaml && ! grep -q "op:" $O/ledger-env.yaml'
check "ledger env: LOG_LEVEL=info, REGION=eu-west, container settings kept" '[ "$(envv LOG_LEVEL)|$(envv REGION)" = "info|eu-west" ] && [ "$(jp -n $NS deploy ledger "{.spec.template.spec.containers[0].image}|{.spec.template.spec.containers[0].resources.requests.memory}")" = "busybox:1.36|8Mi" ]'
check "label-selector patch (tier=backend) in kustomization" 'jq -e "[.patches[]? | select((.target.labelSelector // \"\" | gsub(\" \";\"\"))==\"tier=backend\")] | length==1" <<<"$K"'
check "ledger and audit Pod templates annotated, frontend not" '[ "$(ann ledger)|$(ann audit)|$(ann frontend)" = "true|true|" ] && kubectl -n $NS get deploy frontend'
check "all three Deployments available" 'for d in ledger audit frontend; do kubectl -n $NS rollout status deploy/$d --timeout=90s || exit 1; done && [ "$(jp -n $NS deploy ledger "{.status.readyReplicas}")" = 2 ]'
