#!/usr/bin/env bash
# QA a question end-to-end: setup -> check (should fail) -> reference solve -> check (should all pass)
# Usage: dev/qa.sh <question-id> [setup|check|solve|all]
set -uo pipefail
cd "$(dirname "$0")/.."
Q=$1; STEP=${2:-all}
HOST=$(python3 -c "import json;m=json.load(open('questions/$Q/meta.json'));print(m.get('setup_on',m['host']))")
run() { cat questions/_lib.sh "questions/$Q/$1" | limactl shell --workdir / "$HOST" sudo bash -s; }
case $STEP in
  setup) run setup.sh ;;
  check) run check.sh ;;
  solve) run solve.sh ;;
  all)
    echo "### setup";  run setup.sh >/tmp/qa-$Q-setup.log 2>&1; echo "rc=$? (log /tmp/qa-$Q-setup.log)"
    echo "### check before"; run check.sh | grep -E '^(PASS|FAIL|INFO)'
    echo "### solve";  run solve.sh >/tmp/qa-$Q-solve.log 2>&1; echo "rc=$? (log /tmp/qa-$Q-solve.log)"
    echo "### check after";  run check.sh | grep -E '^(PASS|FAIL|INFO)' ;;
esac
