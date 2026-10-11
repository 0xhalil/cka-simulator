K=/opt/course/s13-dirs/k8s; NS=s13-dirs
yv() { python3 -c "import yaml,sys,json;print(json.dumps(yaml.safe_load(open(sys.argv[1]))))" "$1" 2>/dev/null; }
norm() { jq -r '.resources // [] | .[] | sub("^\\./";"") | sub("/$";"")' | sort | tr '\n' ' '; }
check "api/, cache/, web/ each have a kustomization listing their manifests" 'for d in api web cache; do [ "$(yv $K/$d/kustomization.yaml | norm)" = "deployment.yaml service.yaml " ] || exit 1; done'
check "root kustomization includes only the sub-directories api, cache, web" '[ "$(yv $K/kustomization.yaml | norm)" = "api cache web " ]'
check "root build: namespace s13-dirs, part-of label on all, selectors unchanged, no legacy ConfigMap" 'o=$(kubectl kustomize $K | python3 -c "import yaml,sys,json;print(json.dumps(list(yaml.safe_load_all(sys.stdin))))") && jq -e "length==6 and all(.[]; .metadata.namespace==\"s13-dirs\" and .metadata.labels[\"app.kubernetes.io/part-of\"]==\"bookshop\" and .kind!=\"ConfigMap\") and all(.[] | select(.kind==\"Deployment\"); (.spec.selector.matchLabels|keys)==[\"app\"]) and all(.[] | select(.kind==\"Service\"); (.spec.selector|keys)==[\"app\"])" <<<"$o"'
guard "manifest files unchanged" 'cd $K && sha256sum -c --quiet /root/.s13-dirs.sha'
check "Deployments books-api, books-cache, books-web Ready in s13-dirs" 'for d in books-api books-cache books-web; do kubectl -n $NS rollout status deploy/$d --timeout=90s || exit 1; done'
check "live resources carry app.kubernetes.io/part-of=bookshop" '[ "$(kubectl -n $NS get deploy,svc -l app.kubernetes.io/part-of=bookshop -o name | wc -l)" = 6 ]'
check "legacy ConfigMap not deployed" 'kubectl -n $NS get deploy books-web && ! kubectl -n $NS get cm books-cache-legacy'
