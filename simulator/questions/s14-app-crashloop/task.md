The *ledger* stack in namespace `s14-ledger` consists of three Deployments: `ledger-api`, `ledger-worker` and `ledger-cache`. Since the last change none of them works reliably: Pods are not starting, keep restarting, or are never stable.

Troubleshoot and fix the Deployments so that every Pod of the stack is `Running`, `Ready` and **no longer restarts**.

Requirements:

- `ledger-api` must keep a liveness probe.
- `ledger-worker` must get its log level (`debug`) from the existing ConfigMap `ledger-config` through the environment variable `LOG_LEVEL`.
- `ledger-cache` must still warm up its full in-memory cache (do not change its command).
- Do not change container images or commands, and do not delete the Deployments.
