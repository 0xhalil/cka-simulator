course_dir s12-ops
helm -n s12-ops uninstall catalog checkout payments >/dev/null 2>&1 || true
reset_ns s12-ops
R="--repo https://stefanprodan.github.io/podinfo"
cat > /opt/course/s12-ops/checkout-values.yaml <<'YAML'
replicaCount: 2
ui:
  message: "checkout ready"
image:
  tag: 6.14.1-hotfix
resources:
  requests:
    cpu: 5m
    memory: 16Mi
YAML
chown -R candidate: /opt/course/s12-ops
helm -n s12-ops install catalog podinfo $R --version 6.14.1 --set ui.message=catalog >/dev/null
helm -n s12-ops install payments podinfo $R --version 6.14.0 --set ui.message=payments >/dev/null
helm -n s12-ops install checkout podinfo $R --version 6.14.1 -f /opt/course/s12-ops/checkout-values.yaml --wait --timeout 20s >/dev/null 2>&1
# simulate an interrupted upgrade -> rev2 left in pending-upgrade
helm -n s12-ops upgrade payments podinfo $R --version 6.14.1 --reuse-values --set image.tag=6.99.0 >/dev/null
relstatus() {  # <revision> <status> <description>: rewrite the Helm release record
  local S=sh.helm.release.v1.payments.v$1 B
  B=$(kubectl -n s12-ops get secret $S -o jsonpath='{.data.release}' | base64 -d | base64 -d | gunzip \
    | jq -c --arg s "$2" --arg d "$3" '.info.status=$s | .info.description=$d' | gzip | base64 -w0 | base64 -w0)
  kubectl -n s12-ops patch secret $S --type=merge -p "{\"data\":{\"release\":\"$B\"},\"metadata\":{\"labels\":{\"status\":\"$2\"}}}" >/dev/null
}
relstatus 1 deployed "Install complete"
relstatus 2 pending-upgrade "Preparing upgrade"
helm -n s12-ops list -a
