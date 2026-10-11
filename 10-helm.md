# 10 — Helm Basics

Scope: Helm installation, repo management, chart structure, `install/upgrade/rollback/uninstall`, values override, release history, `template`, `pull`.

---

## Q1 — Repo & search (3%)

1. Add the Bitnami repo `https://charts.bitnami.com/bitnami` as `bitnami` and update.
2. Write all **available versions** of chart `bitnami/nginx` (only the chart version column, newest first, max 5) into `/opt/course/1/versions.txt`.
3. Write the **default value** of `service.type` in `bitnami/nginx` into `/opt/course/1/svc-type.txt`.

<details><summary>Solution</summary>

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo update
helm search repo bitnami/nginx --versions | awk 'NR>1 && NR<=6 {print $2}' > /opt/course/1/versions.txt
helm show values bitnami/nginx | grep -A3 '^service:' | grep type
```

`helm search hub` → Artifact Hub, `helm search repo` → the repos you added.
</details>

---

## Q2 — Install with overrides (5%)

Install release `web` from `bitnami/nginx` chart version **(the second newest from Q1)** into namespace `helm-apps` (create the namespace via Helm) with:

- `replicaCount=3`
- `service.type=NodePort`
- resources defined in a values file `/opt/course/2/values.yaml` (`resources.requests.cpu: 50m`)

<details><summary>Solution</summary>

```bash
cat > /opt/course/2/values.yaml <<EOF
resources:
  requests:
    cpu: 50m
EOF
helm install web bitnami/nginx --version <VER> -n helm-apps --create-namespace \
  --set replicaCount=3 --set service.type=NodePort -f /opt/course/2/values.yaml
helm -n helm-apps list
helm -n helm-apps get values web
k -n helm-apps get deploy,svc
```

`--set` is always applied after `-f` (higher precedence), regardless of order.
</details>

---

## Q3 — Upgrade, history, rollback (6%)

1. Upgrade release `web` to the **newest** chart version, keeping previously set values, and change `replicaCount` to 2.
2. Write the release history to `/opt/course/3/history.txt`.
3. Roll back to revision 1. Write the **current revision number** after rollback to `/opt/course/3/rev.txt`.

<details><summary>Solution</summary>

```bash
helm -n helm-apps upgrade web bitnami/nginx --reuse-values --set replicaCount=2
helm -n helm-apps history web > /opt/course/3/history.txt
helm -n helm-apps rollback web 1
helm -n helm-apps list -o json | jq '.[] | select(.name=="web") | .revision'   # 3 (rollback creates a new revision)
```

Without `--reuse-values`, an upgrade **forgets** the previous `--set` values (reverts to chart defaults).
</details>

---

## Q4 — Find and fix releases (4%)

Several Helm releases exist across namespaces.

1. Find the release that is in **`pending-install`** or **`failed`** state and delete it. Write its `namespace/name` into `/opt/course/4/broken.txt`.
2. Find the release that uses an image `nginx:1.21` (outdated) and write its name into `/opt/course/4/outdated.txt`.

<details><summary>Solution</summary>

```bash
helm list -A -a                     # -a: all states (including failed, pending)
helm list -A --failed --pending
helm -n <ns> uninstall <release>
k get deploy -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{" "}{.spec.template.spec.containers[*].image}{"\n"}{end}' | grep nginx:1.21
helm -n <ns> get manifest <release> | grep image:
```

Releases are stored in Secrets named `sh.helm.release.v1.<name>.v<rev>`: `k get secret -A -l owner=helm`.
</details>

---

## Q5 — Local chart: template & install (5%)

A chart exists in `/opt/course/5/mychart`.

1. Render the templates **without installing** using values `image.tag=1.27` and save the output to `/opt/course/5/rendered.yaml`.
2. The chart fails to install because of a template error. Use `helm lint` to find it, fix it, and install it as release `mychart` in namespace `default`.
3. Download (pull) chart `bitnami/redis` as a `.tgz` into `/opt/course/5/` without extracting.

<details><summary>Solution</summary>

```bash
helm template mychart /opt/course/5/mychart --set image.tag=1.27 > /opt/course/5/rendered.yaml
helm lint /opt/course/5/mychart
# fix the error (typical: unclosed {{ }}, wrong .Values path, Chart.yaml apiVersion)
helm install mychart /opt/course/5/mychart
helm pull bitnami/redis -d /opt/course/5/
```
</details>
