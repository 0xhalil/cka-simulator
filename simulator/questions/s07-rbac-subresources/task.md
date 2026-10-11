The support team (all users in the group **`s07-support`**) needs limited access to namespace `s07-apps` on cluster1.

Create a Role `support` and a RoleBinding `support` in namespace `s07-apps` so that members of the group `s07-support` can **only**:

- `get` and `list` Pods,
- read the **logs** of any Pod,
- open a shell (`kubectl exec`) **only** into the Pod named `debug-shell` — not into any other Pod,
- `get`, `update` and `patch` the ConfigMap `app-config` — but **no** other ConfigMap.

They must not be able to delete Pods or read any other resources.

Afterwards, **impersonating** the user `tom` who is a member of the group `s07-support`, write the logs of Pod `app` into `/opt/course/s07-rbac/app.log`, and write the output of the `kubectl auth can-i` command that checks whether `tom` (group `s07-support`) may `exec` into Pod `payments` in namespace `s07-apps` into `/opt/course/s07-rbac/exec-payments.txt`.
