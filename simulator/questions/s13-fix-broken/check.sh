C=/opt/course/s13-fix; NS=s13-fix; D="-n $NS deploy prod-web"
K=$(python3 -c "import yaml,sys,json;print(json.dumps(yaml.safe_load(open(sys.argv[1]))))" $C/overlays/prod/kustomization.yaml 2>/dev/null)
guard "base manifests unchanged" 'cd $C/base && sha256sum -c --quiet /root/.s13-fix.sha'
check "overlay builds" 'kubectl kustomize $C/overlays/prod >/dev/null'
guard "transformers/generator/patch file still used" 'jq -e "(.images|length>0) and (.replicas|length>0) and (.configMapGenerator|length>0) and ([.patches[]?.path]|index(\"limits.yaml\"))" <<<"$K"'
check "replicas set via replicas transformer to 3" 'kubectl kustomize $C/overlays/prod | grep -q "replicas: 3" && jq -e ".replicas[0].count==3" <<<"$K"'
check "Deployment prod-web: 3 Ready replicas, nginx:1.27-alpine" '[ "$(jp $D "{.spec.template.spec.containers[0].image}")" = nginx:1.27-alpine ] && kubectl rollout status $D --timeout=90s && [ "$(jp $D "{.status.readyReplicas}")" = 3 ]'
check "container web has memory limit 64Mi (requests kept)" '[ "$(jp $D "{.spec.template.spec.containers[?(@.name==\"web\")].resources.limits.memory}|{.spec.template.spec.containers[?(@.name==\"web\")].resources.requests.memory}")" = "64Mi|16Mi" ]'
check "container loads MODE=production from generated ConfigMap prod-web-env-<hash>" 'jp $D "{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}" | grep -Eqx "prod-web-env-[a-z0-9]+" && kubectl -n $NS exec deploy/prod-web -- env | grep -qx MODE=production'
check "Service prod-web has 3 ready endpoints" '[ "$(kubectl -n $NS get endpointslice -l kubernetes.io/service-name=prod-web -o jsonpath="{range .items[*].endpoints[*]}{.conditions.ready}{\"\n\"}{end}" | grep -c true)" = 3 ]'
