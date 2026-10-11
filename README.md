# CKA Simulator

A local, killer.sh-style exam simulator for the **Certified Kubernetes Administrator (CKA)** exam, plus a written practice question bank.

The simulator runs **real kubeadm clusters** in lightweight VMs on your Mac. A web portal shows the tasks next to an embedded terminal and keeps the exam timer. It grades your work automatically against the live cluster state. The exams follow the sections of the KodeKloud / Mumshad Mannambeth *CKA with Practice Tests* course, so you can test yourself after each section and see which lectures to rewatch.

![Kubernetes v1.37](https://img.shields.io/badge/Kubernetes-v1.37-326ce5?logo=kubernetes&logoColor=white) ![macOS on Apple Silicon](https://img.shields.io/badge/macOS-Apple%20Silicon-black?logo=apple) ![Lima VMs](https://img.shields.io/badge/VMs-Lima-orange)

## Features

- **Exam-like environment.** You start on a `base` host without cluster access. Each task names the host to work on (`ssh cka-cp1`), and `sudo -i`, the `k` alias and bash completion are set up.
- **Two clusters, five VMs.** Ubuntu 24.04 with containerd, kubeadm, crictl, etcdctl/etcdutl and helm.
  - **cluster1** (`cka-cp1`, `cka-w1`) runs Kubernetes v1.37 with Calico (NetworkPolicies are enforced), metrics-server, a local-path StorageClass, and Gateway API with NGINX Gateway Fabric.
  - **cluster2** (`cka-cp2`, `cka-w2`) has a control plane on v1.37 and a worker one minor behind for upgrade tasks. It hosts the scenarios that break the control plane, kubelet or etcd.
- **Web portal** (`http://localhost:8888`). It has a task panel, a 2-hour timer that submits automatically, flags, a notepad, multiple terminal tabs and a docs menu. Clicking any code in a task copies it.
- **Automatic grading.** Every task has objective checks against the live cluster. Constraints such as "do not modify X" only count once a real objective has been met.
- **Section exams** (Core Concepts, Scheduling, Logging & Monitoring, Application Lifecycle Management) with three modes:
  - **Random:** about 40 minutes of tasks.
  - **All:** every task in the section.
  - **Weak:** only the tasks you did not fully solve last time.
- **Practice tools** in section exams: **Check** shows which checks pass for the current task, and **Show solution** reveals the explained solution.
- **Review links.** Results link each task you did not fully solve to the course lectures that cover it.
- **Mock Exam A.** 17 tasks over 2 hours on both clusters, scored like the real exam (passing score 66%).

## Requirements

- macOS on Apple Silicon (Lima uses Apple's Virtualization.framework)
- About 9 GB of free RAM for the VMs (quit Docker Desktop while practicing) and about 50 GB of disk
- [Lima](https://lima-vm.io) (`brew install lima`), Python 3 and internet access for the first install

## Quick start

```bash
git clone https://github.com/0xhalil/cka-simulator.git
cd cka-simulator/simulator
./cka up      # creates the VMs and installs both clusters (first run ~20 min)
./cka exam    # opens the exam portal at http://localhost:8888
```

In the portal, pick an exam and press **Prepare**. This builds the scenarios on the clusters, which takes 1–5 minutes. Then press **Start exam**.

| Command | Description |
|---|---|
| `./cka up` | Create VMs and install the clusters (idempotent) |
| `./cka exam [--restart]` | Start or open the portal |
| `./cka status` | VM and node status |
| `./cka stop` / `./cka start` | Stop or start all VMs (state is kept) |
| `./cka ssh <vm>` | Root shell in a VM, for debugging |
| `./cka destroy` | Delete all VMs |

More details are in [simulator/README.md](simulator/README.md).

## Studying with the course

1. Finish a section of the course.
2. Take that section's exam in the simulator (Random mode for a quick round).
3. Use **Check** while working if you want feedback, or skip it for exam conditions.
4. On the results page, rewatch the linked lectures for the tasks you missed. The lobby keeps a list of lectures to review across all exams.
5. Repeat in **Weak** mode until the list is empty. At the end of the course, take **Mock Exam A**.

Lecture links point to `www.udemy.com`. Udemy Business users can set their company domain:

```bash
UDEMY_BASE=https://<company>.udemy.com ./cka exam --restart
```

## Differences from the real exam

- The real exam runs in a PSI remote desktop (XFCE + Firefox). Here the terminal runs in your browser (ttyd).
- Real exam tasks often use a separate cluster per task. Here the tasks share two clusters.
- Documentation opens in a new browser tab.

## Repository layout

```
simulator/
  cka            orchestration CLI (Lima VMs, clusters, portal)
  lima/          VM templates
  provision/     node, control plane and add-on install scripts
  questions/     tasks: task.md, setup.sh, check.sh, solve.sh, solution.md, meta.json
  exams/         exam definitions (section exams + mock exam)
  portal/        web UI and grader (Python standard library only)
  dev/           QA tooling: dev/qa.sh <task> runs setup → check → solve → check
01-…13-*.md      written question bank, one file per course unit
```

Want to add tasks? See [simulator/questions/README.md](simulator/questions/README.md) for the format, helpers and quality rules. Every task is verified end-to-end with `dev/qa.sh` before it is published in an exam.

## Written question bank

Exam-style tasks with hidden solutions (`<details>`), for practicing on any cluster (killercoda, kind, your own kubeadm lab).

| # | Unit | File | Tasks |
|---|------|------|-------|
| 1 | Core Concepts | [01-core-concepts.md](01-core-concepts.md) | 8 |
| 2 | Scheduling (+ Admission Controllers) | [02-scheduling.md](02-scheduling.md) | 10 |
| 3 | Logging & Monitoring | [03-logging-monitoring.md](03-logging-monitoring.md) | 5 |
| 4 | Application Lifecycle Management (+ HPA/VPA) | [04-application-lifecycle.md](04-application-lifecycle.md) | 9 |
| 5 | Cluster Maintenance | [05-cluster-maintenance.md](05-cluster-maintenance.md) | 6 |
| 6 | Security (+ CRD/Operators) | [06-security.md](06-security.md) | 11 |
| 7 | Storage | [07-storage.md](07-storage.md) | 6 |
| 8 | Networking (+ Gateway API) | [08-networking.md](08-networking.md) | 10 |
| 9 | Design & Install (kubeadm) | [09-install-kubeadm.md](09-install-kubeadm.md) | 5 |
| 10 | Helm Basics | [10-helm.md](10-helm.md) | 5 |
| 11 | Kustomize Basics | [11-kustomize.md](11-kustomize.md) | 5 |
| 12 | Troubleshooting | [12-troubleshooting.md](12-troubleshooting.md) | 8 |
| 13 | Other Topics (JSONPath / advanced kubectl) | [13-jsonpath.md](13-jsonpath.md) | 5 |

Conventions:

- Each task names its host or context, like the exam (`ssh cka-xxxx` or `kubectl config use-context …`). Map these to your own lab's node names (`controlplane`, `node01`, `node02`).
- Output files go under `/opt/course/<n>/…`, killer.sh style.
- Weights (%) mirror the exam's difficulty spread: about 16–17 tasks in 2 hours, 66% to pass.

### Exam tips

```bash
alias k=kubectl
export do="--dry-run=client -o yaml"   # k run x --image=nginx $do > x.yaml
export now="--force --grace-period=0"  # k delete pod x $now
source <(kubectl completion bash); complete -o default -F __start_kubectl k
```

- When you forget a field name, use `kubectl explain <resource>.spec --recursive | less`.
- Allowed docs during the exam: kubernetes.io/docs, kubernetes.io/blog, helm.sh/docs, gateway-api.sigs.k8s.io.
- Verify every task (`k get`, `k describe`, `curl`) before moving on.

## Disclaimer

This is an independent study project. It is not affiliated with or endorsed by the CNCF, The Linux Foundation, KodeKloud, Udemy or Killer Shell. No course material is included; the simulator only links to the course's lecture pages. "CKA" and "Certified Kubernetes Administrator" are trademarks of The Linux Foundation.
