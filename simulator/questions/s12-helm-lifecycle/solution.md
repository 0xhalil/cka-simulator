```bash
ssh cka-cp1
helm repo add s12-stefan https://stefanprodan.github.io/podinfo
helm repo update
helm -n s12-life list -a
helm -n s12-life history storefront
# REVISION  STATUS      CHART           DESCRIPTION
# 1         superseded  podinfo-6.12.0  Install complete
# 2         superseded  podinfo-6.13.0  spring campaign
# 3         deployed    podinfo-6.14.0  hotfix attempt     <- faults.unready=true
echo 2 > /opt/course/s12-life/good-revision.txt
helm -n s12-life get values storefront --revision 2     # ui.message / ui.color
helm -n s12-life rollback storefront 2                   # new revision 4: "Rollback to 2"
helm -n s12-life upgrade storefront s12-stefan/podinfo --version 6.14.1 --reuse-values --set replicaCount=2
helm -n s12-life history storefront
k -n s12-life get pods
helm -n s12-life uninstall legacy-cart --keep-history
helm -n s12-life list -a                                 # legacy-cart: uninstalled
helm -n s12-life status legacy-cart
```
Traps:
- Rollback doesn't restore the old revision; it creates a **new** revision as a copy of it.
- `helm upgrade` without `--reuse-values` (or the same values via `-f`) **resets** previous `--set` values → `ui.message` is lost. (`--reset-then-reuse-values` also works.)
- Without `--keep-history`, uninstall deletes the release record.
