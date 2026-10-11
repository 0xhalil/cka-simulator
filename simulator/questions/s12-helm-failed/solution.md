```bash
ssh cka-cp1
helm -n s12-ops list -a
# catalog   deployed
# checkout  failed           <- install --wait timeout (ImagePullBackOff)
# payments  pending-upgrade  <- interrupted upgrade
echo checkout > /opt/course/s12-ops/failed-release.txt
helm -n s12-ops history checkout
helm -n s12-ops get values checkout          # same as the values in the file
k -n s12-ops get pods                         # ImagePullBackOff: podinfo:6.14.1-hotfix
helm show chart podinfo --repo https://stefanprodan.github.io/podinfo --version 6.14.1 | grep appVersion
vi /opt/course/s12-ops/checkout-values.yaml   # image.tag: 6.14.1
helm -n s12-ops upgrade checkout podinfo --repo https://stefanprodan.github.io/podinfo --version 6.14.1 \
  -f /opt/course/s12-ops/checkout-values.yaml
#  (or: helm repo add ... ; helm upgrade checkout <repo>/podinfo --version 6.14.1 -f ...)

helm -n s12-ops history payments
# 1 deployed->superseded  podinfo-6.14.0
# 2 pending-upgrade       podinfo-6.14.1
helm -n s12-ops upgrade payments ...          # Error: another operation (install/upgrade/rollback) is in progress
helm -n s12-ops rollback payments 1           # pending state is cleared, new revision "Rollback to 1"
helm -n s12-ops list -a
```
Notes: deleting and reinstalling a failed release wipes its history — the task wants an in-place repair with `helm upgrade`. Without `--version` the newest chart is installed. No new operation can run on a release in `pending-install/upgrade/rollback` state; return to the last successful revision with `helm rollback`.
