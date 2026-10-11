D="deploy logger-app -n sidecar"
guard "Deployment logger-app still exists" "kubectl get $D"
check "initContainer 'sidecar' with image busybox:1.36" "[ \"\$(jp $D '{.spec.template.spec.initContainers[?(@.name==\"sidecar\")].image}')\" = busybox:1.36 ]"
check "sidecar is a native sidecar (restartPolicy: Always)" "[ \"\$(jp $D '{.spec.template.spec.initContainers[?(@.name==\"sidecar\")].restartPolicy}')\" = Always ]"
check "sidecar runs tail on /var/log/app.log" "jp $D '{.spec.template.spec.initContainers[?(@.name==\"sidecar\")].command} {.spec.template.spec.initContainers[?(@.name==\"sidecar\")].args}' | grep -q 'tail.*/var/log/app.log'"
check "volume 'logs' mounted at /var/log in both containers" "[ \"\$(jp $D '{.spec.template.spec.containers[?(@.name==\"app\")].volumeMounts[?(@.name==\"logs\")].mountPath}')\" = /var/log ] && [ \"\$(jp $D '{.spec.template.spec.initContainers[?(@.name==\"sidecar\")].volumeMounts[?(@.name==\"logs\")].mountPath}')\" = /var/log ]"
guard "original container 'app' unchanged (image busybox:1.36)" "[ \"\$(jp $D '{.spec.template.spec.containers[?(@.name==\"app\")].image}')\" = busybox:1.36 ]"
check "rollout complete and sidecar logs show application lines" '
  kubectl -n sidecar rollout status deploy/logger-app --timeout=60s >/dev/null || exit 1; sleep 4
  for p in $(kubectl -n sidecar get pod -l app=logger-app -o jsonpath="{range .items[?(@.spec.initContainers[0].name==\"sidecar\")]}{.metadata.name} {end}"); do
    kubectl -n sidecar logs $p -c sidecar --tail=20 | grep -q "legacy-app processed order" && exit 0
  done; exit 1'
