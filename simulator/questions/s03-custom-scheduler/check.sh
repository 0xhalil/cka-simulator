D="deploy custom-scheduler -n s03-sched"; P="pod -n s03-sched"
by() {  # pod -> name of scheduler that bound it (from the Scheduled event)
  kubectl -n s03-sched get events.events.k8s.io --field-selector reason=Scheduled,regarding.name=$1 -o jsonpath='{.items[*].reportingController}'
}
check "Deployment custom-scheduler runs image registry.k8s.io/kube-scheduler:v1.37.1 with ServiceAccount custom-scheduler" \
  '[ "$(jp $D "{.spec.template.spec.containers[0].image}|{.spec.template.spec.serviceAccountName}")" = "registry.k8s.io/kube-scheduler:v1.37.1|custom-scheduler" ]'
check "custom-scheduler reads its config from ConfigMap custom-scheduler-config" \
  'kubectl get cm custom-scheduler-config -n s03-sched && [ "$(jp $D "{.spec.template.spec.volumes[*].configMap.name}")" = custom-scheduler-config ]'
check "Deployment custom-scheduler is available with its Pod running on cka-cp1" 'kubectl -n s03-sched rollout status deploy/custom-scheduler --timeout=30s && [ "$(jp $D "{.status.readyReplicas}")" = 1 ] && [ "$(kubectl -n s03-sched get pod -o json | jq -r "[.items[] | select(.metadata.ownerReferences[0].kind==\"ReplicaSet\" and .status.phase==\"Running\") | .spec.nodeName] | unique | join(\",\")")" = cka-cp1 ]'
check "Pod custom-pod uses schedulerName s03-custom-scheduler and is Running" \
  'for i in $(seq 1 15); do [ "$(jp $P custom-pod "{.spec.schedulerName}/{.status.phase}")" = s03-custom-scheduler/Running ] && exit 0; sleep 2; done; exit 1'
check "custom-pod was scheduled by s03-custom-scheduler (Scheduled event)" '[ "$(by custom-pod)" = s03-custom-scheduler ] '
check "Pod binpack-pod uses schedulerName s03-binpack-scheduler, is Running and was scheduled by it" \
  'for i in $(seq 1 15); do [ "$(jp $P binpack-pod "{.spec.schedulerName}/{.status.phase}")" = s03-binpack-scheduler/Running ] && [ "$(by binpack-pod)" = s03-binpack-scheduler ] && exit 0; sleep 2; done; exit 1'
check "profile s03-binpack-scheduler uses NodeResourcesFit scoringStrategy MostAllocated; s03-custom-scheduler profile does not; leader election disabled" \
  'kubectl -n s03-sched get cm custom-scheduler-config -o json | python3 -c "
import json, sys, yaml
for v in json.load(sys.stdin)[\"data\"].values():
    c = yaml.safe_load(v)
    if not isinstance(c, dict) or c.get(\"kind\") != \"KubeSchedulerConfiguration\": continue
    st = lambda p: [a.get(\"args\", {}).get(\"scoringStrategy\", {}).get(\"type\") for a in p.get(\"pluginConfig\") or [] if a.get(\"name\") == \"NodeResourcesFit\"]
    pr = {p.get(\"schedulerName\"): p for p in c.get(\"profiles\", [])}
    ok = c.get(\"leaderElection\", {}).get(\"leaderElect\") is False and \"MostAllocated\" in st(pr.get(\"s03-binpack-scheduler\", {})) and \"MostAllocated\" not in st(pr.get(\"s03-custom-scheduler\", {\"x\": 1}))
    sys.exit(0 if ok else 1)
sys.exit(1)"'
