#!/usr/bin/env python3
"""Generate one exam per course section from questions/*/meta.json (exams/section-NN.json).
Duration follows the real exam ratio: 120 minutes for 100 weight points."""
import json, os, glob, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cur = json.load(open(os.path.join(ROOT, "portal", "curriculum.json")))
by = {}
for m in sorted(glob.glob(os.path.join(ROOT, "questions", "*", "meta.json"))):
    qid = os.path.basename(os.path.dirname(m))
    meta = json.load(open(m))
    if "section" in meta and meta.get("verified"):
        by.setdefault(int(meta["section"]), []).append((qid, meta))
# small sections are merged into a neighbour so every exam has enough tasks
merge = {4: 4, 10: 11, 15: 15}
for f in glob.glob(os.path.join(ROOT, "exams", "section-*.json")):
    os.remove(f)
for sec, qs in sorted(by.items()):
    target = merge.get(sec, sec)
    if target != sec:
        by.setdefault(target, [])
groups = {}
for sec, qs in by.items():
    groups.setdefault(merge.get(sec, sec), []).extend(qs)
# publish only the requested sections (default: those whose task pool is complete)
PUBLISH = {int(a) for a in sys.argv[1:]} or {2, 3, 4, 5}
for sec, qs in sorted(groups.items()):
    if not qs or sec not in PUBLISH:
        continue
    qs.sort(key=lambda x: (x[1].get("setup_priority", 50), x[0]))
    weight = sum(m["weight"] for _, m in qs)
    minutes = max(20, round(weight * 1.2 / 5) * 5)
    secs = sorted({m["section"] for _, m in qs})
    title = " + ".join(cur[str(s)]["title"] for s in secs)
    exam = {"title": title, "kind": "section", "section": sec, "duration_minutes": minutes,
            "description": f"Section {', '.join(map(str, secs))}", "questions": [q for q, _ in qs]}
    json.dump(exam, open(os.path.join(ROOT, "exams", f"section-{sec:02d}.json"), "w"), indent=1)
    print(f"section-{sec:02d}: {len(qs)} tasks, {weight} pts, {minutes} min — {title}")
