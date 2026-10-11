#!/usr/bin/env bash
# QA several questions one after another; pauses while the portal is grading a real exam,
# and deletes each question's namespaces afterwards (keeps the shared worker free).
cd "$(dirname "$0")/.."
for q in "$@"; do
  while curl -s --max-time 3 localhost:8888/api/state | grep -q '"status": "grading"'; do sleep 10; done
  echo "======== $q"
  dev/qa.sh "$q" all 2>&1 | grep -E '^(###|PASS|FAIL|INFO|rc=)'
  host=$(python3 -c "import json;print(json.load(open('questions/$q/meta.json'))['host'])")
  ns=$(grep -ho 'reset_ns [a-z0-9 -]*' "questions/$q/setup.sh" | head -1 | cut -d' ' -f2-)
  [ -n "$ns" ] && limactl shell --workdir / "$host" sudo kubectl --kubeconfig /etc/kubernetes/admin.conf delete ns $ns --wait=false >/dev/null 2>&1
done
