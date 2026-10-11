#!/usr/bin/env python3
"""CKA simulator exam portal (stdlib only).

Serves the exam UI, prepares scenarios inside the Lima VMs, keeps the timer and grades the result.
Run via ./cka exam  ->  http://localhost:8888
"""
import json
import os
import random
import subprocess
import sys
import threading
import time
from http.server import HTTPServer, SimpleHTTPRequestHandler

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QDIR = os.path.join(ROOT, "questions")
EDIR = os.path.join(ROOT, "exams")
STATIC = os.path.join(ROOT, "portal", "static")
STATE_FILE = os.path.join(ROOT, "state", "exam.json")
LOG_DIR = os.path.join(ROOT, "state", "logs")
PORT = int(os.environ.get("PORT", "8888"))
LIB = open(os.path.join(QDIR, "_lib.sh")).read()
HISTORY_FILE = os.path.join(ROOT, "state", "history.json")
# Udemy Business users can point this at their company domain: UDEMY_BASE=https://<company>.udemy.com
COURSE_URL = os.environ.get("UDEMY_BASE", "https://www.udemy.com") + "/course/certified-kubernetes-administrator-with-practice-tests/learn/lecture/"
CURRICULUM = json.load(open(os.path.join(ROOT, "portal", "curriculum.json")))
LECTURES = {l["id"]: {"id": l["id"], "title": l["title"], "section": int(sec), "url": COURSE_URL + str(l["id"])}
            for sec, v in CURRICULUM.items() for l in v["lectures"]}


def section_title(n):
    return CURRICULUM.get(str(n), {}).get("title", "")


def load_history():
    try:
        with open(HISTORY_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def append_history(entry):
    h = load_history()
    h.append(entry)
    with open(HISTORY_FILE, "w") as f:
        json.dump(h, f, indent=1)

lock = threading.Lock()


def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE) as f:
            return json.load(f)
    return {"status": "idle"}


state = load_state()


def save_state():
    tmp = STATE_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f, indent=1)
    os.replace(tmp, STATE_FILE)


def read(path, default=""):
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        return default


def question(qid):
    d = os.path.join(QDIR, qid)
    meta = json.loads(read(os.path.join(d, "meta.json")))
    meta["id"] = qid
    meta["task"] = read(os.path.join(d, "task.md"))
    meta["section_title"] = section_title(meta.get("section"))
    return meta


def exams():
    out = []
    for f in sorted(os.listdir(EDIR)):
        if f.endswith(".json"):
            e = json.loads(read(os.path.join(EDIR, f)))
            e["id"] = f[:-5]
            e.setdefault("kind", "mock")
            out.append(e)
    hist = load_history()
    for e in out:
        runs = [h for h in hist if h["exam"] == e["id"]]
        e["attempts"] = len(runs)
        e["best"] = max((h["score_pct"] for h in runs), default=None)
        e["last"] = runs[-1]["score_pct"] if runs else None
        ls = latest_scores()
        e["weak"] = sum(1 for q in e["questions"] if q in ls and ls[q][0] < ls[q][1])
    return sorted(out, key=lambda e: (e["kind"] != "section", e.get("section", 99), e["id"]))


def run_in_vm(host, script_path, log_name, timeout=900):
    """Run a question script as root inside a VM with the shared helper library prepended."""
    body = LIB + "\n" + read(script_path)
    os.makedirs(LOG_DIR, exist_ok=True)
    try:
        p = subprocess.run(
            ["limactl", "shell", "--workdir", "/", host, "sudo", "bash", "-s"],
            input=body, capture_output=True, text=True, timeout=timeout,
        )
        out, rc = p.stdout + p.stderr, p.returncode
    except subprocess.TimeoutExpired as e:
        out, rc = f"{e.stdout or ''}{e.stderr or ''}\nTIMEOUT after {timeout}s", 124
    with open(os.path.join(LOG_DIR, log_name), "w") as f:
        f.write(out)
    return rc, out


def latest_scores():
    """Latest score per question across all attempts: {qid: (score, weight)}."""
    out = {}
    for h in load_history():
        for q in h["questions"]:
            out[q["id"]] = (q["score"], q["weight"])
    return out


def pick_questions(exam, mode):
    pool = list(exam["questions"])
    if exam.get("kind") != "section" or mode == "all":
        return pool
    if mode == "weak":
        ls = latest_scores()
        return [q for q in pool if q in ls and ls[q][0] < ls[q][1]]
    # random: ~40 exam-minutes worth of tasks (at most 7), different every attempt
    random.shuffle(pool)
    picked, weight = [], 0
    for q in pool:
        if len(picked) >= 7 or weight >= 33:
            break
        picked.append(q)
        weight += question(q)["weight"]
    return picked


def duration_for(qs):
    w = sum(question(q)["weight"] for q in qs)
    return max(15, round(w * 1.2 / 5) * 5) * 60


def prepare(exam_id, mode="all"):
    exam = next(e for e in exams() if e["id"] == exam_id)
    qs = pick_questions(exam, mode)
    with lock:
        state.clear()
        state.update({
            "status": "preparing", "exam": exam_id, "title": exam["title"] + ({"random": "", "weak": " (weak)", "all": " (all)"}.get(mode, "") if exam.get("kind") == "section" else ""),
            "mode": mode,
            "practice": exam.get("kind") == "section",
            "duration": exam.get("duration_minutes", 120) * 60 if exam.get("kind") != "section" else duration_for(qs),
            "questions": qs, "progress": [], "flagged": [], "notes": "",
        })
        save_state()
    # some scenarios must be prepared before others on the same node (e.g. reset a node, then break it)
    order = sorted(qs, key=lambda q: question(q).get("setup_priority", 50))
    for i, qid in enumerate(order, 1):
        meta = question(qid)
        rc, out = run_in_vm(meta.get("setup_on", meta["host"]), os.path.join(QDIR, qid, "setup.sh"), f"setup-{qid}.log")
        with lock:
            state["progress"].append({"q": i, "id": qid, "ok": rc == 0})
            save_state()
    with lock:
        failed = [p for p in state["progress"] if not p["ok"]]
        state["setup_errors"] = [p["id"] for p in failed]
        state["status"] = "ready"
        save_state()


def run_checks(qid):
    """Run a question's check.sh and return (checks, passed_fraction)."""
    meta = question(qid)
    rc, out = run_in_vm(meta.get("check_on", meta["host"]), os.path.join(QDIR, qid, "check.sh"), f"check-{qid}.log", timeout=300)
    checks = []
    for line in out.splitlines():
        if line.startswith("PASS ") or line.startswith("FAIL "):
            checks.append({"ok": line.startswith("PASS"), "text": line[5:]})
    for c in checks:
        c["guard"] = c["text"].startswith("[guard] ")
        if c["guard"]:
            c["text"] = c["text"][8:] + "  (constraint)"
    passed = sum(c["ok"] for c in checks)
    total = len(checks) or 1
    # constraints ("do not modify X") only count once at least one real objective was achieved
    if not any(c["ok"] and not c["guard"] for c in checks):
        passed = 0
    return checks, passed / total


check_lock = threading.Lock()


def live_check(qid):
    """On-demand check during a practice exam (one at a time to keep the clusters responsive)."""
    with check_lock:
        checks, frac = run_checks(qid)
    with lock:
        state.setdefault("checks", {})[qid] = {"status": "done", "checks": checks, "pct": round(100 * frac), "at": time.time()}
        save_state()


def grade():
    results = []
    for i, qid in enumerate(state["questions"], 1):
        meta = question(qid)
        checks, frac = run_checks(qid)
        results.append({
            "q": i, "id": qid, "title": meta["title"], "weight": meta["weight"],
            "domain": meta.get("domain", ""), "checks": checks,
            "section": meta.get("section"), "section_title": section_title(meta.get("section")),
            "lectures": [LECTURES[l] for l in meta.get("lectures", []) if l in LECTURES],
            "score": round(meta["weight"] * frac, 2),
            "solution": read(os.path.join(QDIR, qid, "solution.md")),
        })
        with lock:
            state["grading_progress"] = i
            save_state()
    total_w = sum(r["weight"] for r in results)
    score = sum(r["score"] for r in results)
    with lock:
        state["results"] = results
        state["score_pct"] = round(100 * score / total_w, 1) if total_w else 0
        state["passed"] = state["score_pct"] >= 66
        state["status"] = "finished"
        state["finished_at"] = time.time()
        save_state()
        append_history({
            "exam": state["exam"], "title": state["title"], "finished_at": state["finished_at"],
            "score_pct": state["score_pct"],
            "questions": [{"id": r["id"], "title": r["title"], "score": r["score"], "weight": r["weight"],
                           "lectures": [l["id"] for l in r["lectures"]] if r["score"] < r["weight"] else [],
                           "missed": [c["text"] for c in r["checks"] if not c["ok"]]} for r in results],
        })


def public_state():
    with lock:
        s = dict(state)
    if s.get("status") in ("running", "grading", "finished") or s.get("status") == "ready":
        s["question_data"] = [question(q) for q in s.get("questions", [])]
    if s.get("status") == "running" and s.get("practice"):
        s["solutions"] = {q: read(os.path.join(QDIR, q, "solution.md")) for q in s.get("revealed", [])}
    if s.get("status") == "running":
        s["remaining"] = max(0, int(s["started_at"] + s["duration"] - time.time()))
    s["exams"] = exams()
    s["history"] = load_history()[-30:]
    # lectures to rewatch: from the latest attempt of every exam
    latest = {}
    for h in load_history():
        latest[h["exam"]] = h
    review = {}
    for h in latest.values():
        for q in h["questions"]:
            for lid in q.get("lectures", []):
                if lid in LECTURES:
                    r = review.setdefault(lid, dict(LECTURES[lid], tasks=[]))
                    r["tasks"].append(q.get("title", q["id"]))
    s["review"] = sorted(review.values(), key=lambda l: (l["section"], l["id"]))
    s["now"] = time.time()
    return s


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=STATIC, **kw)

    def log_message(self, fmt, *args):
        pass

    def end_headers(self):
        # never let the browser cache the UI (it changes while the simulator evolves)
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def send_json(self, obj, code=200):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def body(self):
        n = int(self.headers.get("Content-Length", 0))
        return json.loads(self.rfile.read(n) or b"{}")

    def do_GET(self):
        if self.path.startswith("/api/state"):
            return self.send_json(public_state())
        return super().do_GET()

    def do_POST(self):
        data = self.body()
        if self.path == "/api/prepare":
            if state.get("status") in ("preparing", "running", "grading"):
                return self.send_json({"error": "exam in progress"}, 409)
            exam = next((e for e in exams() if e["id"] == data.get("exam")), None)
            if not exam:
                return self.send_json({"error": "unknown exam"}, 404)
            mode = data.get("mode", "random")
            if not pick_questions(exam, mode):
                return self.send_json({"error": "No tasks for this mode (no weak tasks yet)."}, 400)
            threading.Thread(target=prepare, args=(data["exam"], mode), daemon=True).start()
            return self.send_json({"ok": True})
        if self.path == "/api/start":
            with lock:
                if state.get("status") == "ready":
                    state["status"] = "running"
                    state["started_at"] = time.time()
                    save_state()
            return self.send_json({"ok": True})
        if self.path == "/api/flag":
            with lock:
                f = set(state.get("flagged", []))
                f.symmetric_difference_update({data["id"]})
                state["flagged"] = sorted(f)
                save_state()
            return self.send_json({"ok": True})
        if self.path == "/api/check":
            qid = data.get("id")
            with lock:
                ok = state.get("status") == "running" and state.get("practice") and qid in state.get("questions", [])
                busy = state.get("checks", {}).get(qid, {}).get("status") == "running"
                if ok and not busy:
                    state.setdefault("checks", {})[qid] = {"status": "running", "at": time.time()}
                    save_state()
            if not ok:
                return self.send_json({"error": "checks are only available in section (practice) exams"}, 400)
            if not busy:
                threading.Thread(target=live_check, args=(qid,), daemon=True).start()
            return self.send_json({"ok": True})
        if self.path == "/api/reveal":
            with lock:
                if state.get("status") == "running" and state.get("practice") and data.get("id") in state.get("questions", []):
                    r = set(state.get("revealed", [])); r.add(data["id"]); state["revealed"] = sorted(r)
                    save_state()
            return self.send_json({"ok": True})
        if self.path == "/api/notes":
            with lock:
                state["notes"] = data.get("notes", "")
                save_state()
            return self.send_json({"ok": True})
        if self.path == "/api/finish":
            with lock:
                if state.get("status") != "running":
                    return self.send_json({"error": "not running"}, 409)
                state["status"] = "grading"
                state["grading_progress"] = 0
                state["ended_at"] = time.time()
                save_state()
            threading.Thread(target=grade, daemon=True).start()
            return self.send_json({"ok": True})
        if self.path == "/api/reset":
            with lock:
                if state.get("status") in ("preparing", "grading"):
                    return self.send_json({"error": "busy"}, 409)
                state.clear()
                state["status"] = "idle"
                save_state()
            return self.send_json({"ok": True})
        self.send_json({"error": "not found"}, 404)


def timer_watchdog():
    """Auto-submit when time is up, like the real exam."""
    while True:
        time.sleep(5)
        with lock:
            due = state.get("status") == "running" and time.time() > state["started_at"] + state["duration"]
            if due:
                state["status"] = "grading"
                state["grading_progress"] = 0
                state["ended_at"] = time.time()
                save_state()
        if due:
            grade()


if __name__ == "__main__":
    if state.get("status") in ("preparing", "grading"):
        # server was killed mid-way; allow restarting cleanly
        state["status"] = "idle" if state["status"] == "preparing" else "running"
        save_state()
    if str(state.get("exam", "")).startswith("section-") and "practice" not in state:
        state["practice"] = True   # exams prepared before practice mode existed
        save_state()
    threading.Thread(target=timer_watchdog, daemon=True).start()
    print(f"CKA simulator portal: http://localhost:{PORT}")
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
