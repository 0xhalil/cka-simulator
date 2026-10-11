A Kustomize base with three Deployments exists at `/opt/course/s13-patch/base`. Create the overlay `/opt/course/s13-patch/overlays/staging/kustomization.yaml` (don't modify `base`) that deploys into namespace `s13-patch` and contains these patches:

1. An **inline JSON6902** patch for Deployment `ledger` that sets the replicas to `2` and **removes** the (broken) `livenessProbe` of its container.
2. A **strategic merge** patch stored in the separate file `overlays/staging/ledger-env.yaml` that changes the `LOG_LEVEL` env of container `ledger` to `info` and adds the env variable `REGION=eu-west`, keeping all other container settings.
3. One single patch that selects Deployments **by the label** `tier=backend` (not by name) and adds the annotation `backup.s13/enabled: "true"` to their **Pod template**. Deployments without that label must not get it.

Apply the overlay with `kubectl`. All Deployments must be available.
