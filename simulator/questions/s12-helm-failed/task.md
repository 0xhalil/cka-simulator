Several Helm releases are installed in namespace `s12-ops` (use `helm list -a`). Two of them are unhealthy. All releases use the chart `podinfo` from the repository `https://stefanprodan.github.io/podinfo`.

1. Write the name of the release that is in status **`failed`** to `/opt/course/s12-ops/failed-release.txt`.
2. That release was installed from the values file `/opt/course/s12-ops/checkout-values.yaml`, which contains a wrong image tag (the tag must match the chart's appVersion). Fix the image tag **in the values file** and repair the release on its current chart version **without uninstalling it** (its history must keep the failed revision). All other values of the file must stay in effect, and all of its Pods must be Ready.
3. The release whose upgrade was interrupted is stuck in a **`pending-*`** status and cannot be upgraded anymore. Bring it back to its **last successfully deployed** revision, without uninstalling it.
4. Don't touch the healthy release.
