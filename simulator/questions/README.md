# Writing simulator questions

Each question is a folder `questions/<id>/` (id = short kebab-case, unique):

| File | Purpose |
|------|---------|
| `meta.json` | `{"title", "host", "weight", "domain", "section", "lectures", ["setup_priority"]}` |
| `task.md` | Task text shown to the candidate (English, exam style, Markdown) |
| `setup.sh` | Builds the scenario. Must be **idempotent** (re-runnable for every new attempt) |
| `check.sh` | Grades the result: prints `PASS <text>` / `FAIL <text>` lines |
| `solve.sh` | Reference solution as a script (used only for QA, never shown) |
| `solution.md` | Explanation shown after grading (Turkish notes, commands/YAML in English) |

## meta.json

```json
{"title": "Static Pod on a worker", "host": "cka-cp1", "weight": 5,
 "domain": "Workloads & Scheduling", "section": 3, "lectures": [14863335]}
```

- `host`: where the candidate must `ssh` to. Also where setup/check/solve run (as root, `KUBECONFIG=/etc/kubernetes/admin.conf`).
  - `cka-cp1` → cluster1 (`cka-cp1` control plane + `cka-w1` worker, v1.37). Default for everything that does **not** break the cluster.
  - `cka-cp2` → cluster2 (`cka-cp2` + `cka-w2`, worker one minor behind). Use for anything that edits static pod manifests, apiserver/scheduler/controller-manager flags, kubelet config, certificates, etcd, drains/upgrades/rejoins nodes.
- `weight`: 2–8 (exam % weight; harder = higher).
- `domain`: one of `Cluster Architecture, Installation & Configuration`, `Workloads & Scheduling`, `Services & Networking`, `Storage`, `Troubleshooting`.
- `section`: course section number (2 = Core Concepts … 15 = Other Topics), see `portal/curriculum.json`.
- `lectures`: Udemy lecture ids (from `portal/curriculum.json`) the candidate should rewatch if they fail this task. 1–3 ids, most relevant first.
- `setup_priority` (optional, default 50): lower runs first. Use when a scenario must be prepared before another one on the same node.

## Helpers available in setup/check/solve (`_lib.sh` is prepended)

- `check "<text>" '<shell condition>'` → `PASS/FAIL <text>`. The condition is `eval`ed in a subshell.
- `guard "<text>" '<condition>'` → a constraint such as "don't modify X". Guards only score if at least one real objective passed (doing nothing must give 0).
- `jp <kubectl get args...> '<jsonpath>'` → value or empty string.
- `on <node> '<cmd>'` → run as root on another node via ssh (stdin is closed).
- `reset_ns ns1 ns2 ...` → delete + recreate namespaces (use it in setup).
- `course_dir <name>` → fresh `/opt/course/<name>/` owned by `candidate` (for files the candidate must create/read).
- `wait_deploy <ns> <name> [timeout]`.

## Rules (quality bar: killer.sh)

1. **Realistic exam tasks**, not quiz questions. The candidate must *do* something on the cluster or produce a file. Base scenarios on what the course lectures teach (`state/transcripts/sections/sec-NN.md`), but make them exam-hard: multi-step, a trap or two, exact names, things that need docs/`kubectl explain`.
2. Namespaces and cluster-scoped object names must be unique to the question (prefix with something specific). Never touch objects of other questions.
3. `setup.sh` must fully reset its scenario (delete old objects, recreate). It must leave cluster1 healthy.
4. Every objective has its own `check` line, phrased as the requirement ("Deployment x has 3 ready replicas"). Checks verify **live state** (and files), are objective, and accept every valid solution (e.g. imperative or declarative, either order). Avoid flaky timing: use `kubectl wait`, `rollout status` or small retry loops.
5. Before solving, all non-guard checks must FAIL; after `solve.sh` all checks must PASS. Verify with `dev/qa.sh <id>`.
6. Images: prefer `busybox:1.36`, `nginx:1.27-alpine`, `httpd:2.4-alpine`, `redis:7-alpine`. Keep memory small (nodes have 2 GiB).
7. Task text: English, like the real exam ("Create…", "Ensure…", "Write … to /opt/course/…"). Don't reveal the solution.
8. `solution.md`: short Turkish explanation + exact commands/YAML; mention the trap.
9. Quoting in `check.sh`: prefer single-quoted conditions; inside them use `"$(jp ...)"`. Test with `dev/qa.sh <id> check`.
