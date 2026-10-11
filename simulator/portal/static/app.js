// CKA simulator exam UI
const $ = (s) => document.querySelector(s);
const TERM_URL = `http://${location.hostname}:7681/`;
let S = null;          // last server state
let cur = 0;           // current question index
let termCount = 0;
let notesTimer = null;

async function api(path, body) {
  const r = await fetch(path, body ? { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) } : {});
  return r.json();
}

function show(id) {
  for (const s of document.querySelectorAll(".screen")) s.classList.add("hidden");
  $(id).classList.remove("hidden");
}

function fmt(sec) {
  const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60;
  return (h ? h + ":" : "") + String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
}

// ---------------------------------------------------------------- lobby
function renderLobby() {
  show("#lobby");
  const list = $("#exam-list");
  const busy = S.status === "preparing" || S.status === "ready";
  list.classList.toggle("hidden", busy);
  const item = e => {
    const score = e.attempts ? `<span class="${e.last >= 66 ? "pass" : "fail"}">last: ${e.last}%</span> · best: ${e.best}% · ${e.attempts} attempt${e.attempts > 1 ? "s" : ""}` : "not taken yet";
    const label = e.kind === "section" ? `<span class="secno">S${e.section}</span> ${e.title}` : e.title;
    return `<div class="exam-item">
      <div><h3>${label}</h3><p class="muted">${e.kind === "section" ? "pool of " + e.questions.length + " tasks" : e.questions.length + " tasks · " + (e.duration_minutes || 120) + " min"} · ${score}</p></div>
      <div class="btns">${e.kind === "section"
        ? `<button class="primary" data-exam="${e.id}" data-mode="random" title="A random ~40 minute set of tasks from the pool">Random</button>
           <button data-exam="${e.id}" data-mode="all">All (${e.questions.length})</button>
           <button data-exam="${e.id}" data-mode="weak" ${e.weak ? "" : "disabled"} title="Tasks you did not fully solve last time">Weak (${e.weak || 0})</button>`
        : `<button class="primary" data-exam="${e.id}" data-mode="all">Prepare</button>`}</div>
    </div>`;
  };
  const secs = S.exams.filter(e => e.kind === "section"), mocks = S.exams.filter(e => e.kind !== "section");
  list.innerHTML = (secs.length ? `<h3 class="group">Section exams</h3>` + secs.map(item).join("") : "")
    + (mocks.length ? `<h3 class="group">Mock exam</h3>` + mocks.map(item).join("") : "");
  $("#review").classList.toggle("hidden", busy || !S.review || !S.review.length);
  $("#review-list").innerHTML = (S.review || []).map(l =>
    `<li><a href="${l.url}" target="_blank">S${l.section} · ${l.title}</a> <span class="muted">— ${[...new Set(l.tasks)].join(", ")}</span></li>`).join("");
  list.querySelectorAll("button[data-exam]").forEach(b => b.onclick = async () => {
    b.disabled = true;
    const r = await api("/api/prepare", { exam: b.dataset.exam, mode: b.dataset.mode });
    if (r.error) { alert(r.error); b.disabled = false; }
    poll();
  });
  $("#prep").classList.toggle("hidden", S.status !== "preparing");
  $("#ready").classList.toggle("hidden", S.status !== "ready");
  if (S.status === "preparing") {
    const n = S.questions.length, d = S.progress.length;
    $("#prep-bar").style.width = (100 * d / n) + "%";
    $("#prep-text").textContent = `Setting up task ${Math.min(d + 1, n)} of ${n} on the clusters…`;
  }
  if (S.status === "ready" && S.setup_errors && S.setup_errors.length) {
    $("#ready-warn").classList.remove("hidden");
    $("#ready-warn").textContent = `Setup failed for: ${S.setup_errors.join(", ")} (see simulator/state/logs/setup-*.log)`;
  }
}
$("#start-btn").onclick = async () => { await api("/api/start", {}); cur = 0; poll(); };

// ---------------------------------------------------------------- exam
function renderExam() {
  show("#exam");
  $("#exam-title").textContent = S.title;
  if (!termCount) addTerminal();
  const qs = S.question_data;
  $("#qnav").innerHTML = qs.map((q, i) =>
    `<button class="${i === cur ? "current" : ""} ${S.flagged.includes(q.id) ? "flagged" : ""}" data-i="${i}" title="${q.title}">${i + 1}</button>`).join("");
  $("#qnav").querySelectorAll("button").forEach(b => b.onclick = () => { cur = +b.dataset.i; renderQuestion(); renderExam(); });
  renderQuestion();
  renderCheck();
  if ($("#notes-text") !== document.activeElement) $("#notes-text").value = S.notes || "";
}

let renderedQ = null;
function renderQuestion() {
  const q = S.question_data[cur];
  $("#flag-btn").classList.toggle("on", S.flagged.includes(q.id));
  if (renderedQ === q.id) return;
  renderedQ = q.id;
  $("#qnum").textContent = `Question ${cur + 1} of ${S.question_data.length}`;
  $("#qmeta").textContent = `Task weight: ${q.weight}% · ${q.domain}`;
  $("#hostbox").innerHTML = `You must connect to the correct host. Failure to do so may result in a zero score.<br>
    <code>[candidate@base] $ ssh ${q.host}</code>`;
  $("#qbody").innerHTML = marked.parse(q.task);
  $("#qbody").scrollTop = 0;
  $("#prev-btn").disabled = cur === 0;
  $("#next-btn").disabled = cur === S.question_data.length - 1;
  for (const el of document.querySelectorAll(".md code, .md pre, .hostbox code")) {
    el.onclick = (ev) => {
      ev.stopPropagation();
      let t = (el.tagName === "PRE" ? el.innerText : el.textContent).trim();
      t = t.replace(/^\[candidate@base\] \$ /, "");
      navigator.clipboard.writeText(t);
      el.classList.add("copied"); setTimeout(() => el.classList.remove("copied"), 500);
    };
  }
}
// practice mode: on-demand check + solution reveal (section exams only)
let shownCheckAt = null, shownReveal = null;
function renderCheck() {
  const q = S.question_data[cur];
  $("#checkbox").classList.toggle("hidden", !S.practice);
  if (!S.practice) return;
  const c = (S.checks || {})[q.id];
  const running = c && c.status === "running";
  $("#check-btn").disabled = running;
  $("#check-btn").textContent = running ? "Checking…" : "Check";
  const key = q.id + ":" + (c ? c.status + c.at : "none");
  if (shownCheckAt !== key) {
    shownCheckAt = key;
    if (!c) { $("#check-status").textContent = ""; $("#check-list").innerHTML = ""; }
    else if (running) { $("#check-status").textContent = "Running the checks on the cluster (10–60 s)…"; }
    else {
      const t = new Date(c.at * 1000).toLocaleTimeString();
      $("#check-status").innerHTML = `<b class="${c.pct === 100 ? "pass" : c.pct === 0 ? "fail" : ""}">${c.pct}%</b> · ${t}`;
      $("#check-list").innerHTML = (c.checks || []).map(x => `<div class="check ${x.ok ? "ok" : "no"}">${escapeHtml(x.text)}</div>`).join("")
        || "<div class='check no'>The checks did not run (see state/logs/check-*.log)</div>";
    }
  }
  const sol = (S.solutions || {})[q.id];
  const rkey = q.id + ":" + (sol ? 1 : 0);
  if (shownReveal !== rkey) {
    shownReveal = rkey;
    $("#reveal").classList.toggle("hidden", !sol);
    $("#reveal").innerHTML = sol ? "<h3>Solution</h3>" + marked.parse(sol) : "";
    $("#reveal-btn").disabled = !!sol;
  }
}
$("#check-btn").onclick = async () => {
  const q = S.question_data[cur];
  $("#check-btn").disabled = true;
  await api("/api/check", { id: q.id });
  poll();
};
$("#reveal-btn").onclick = async () => {
  if (!confirm("Show the solution for this task?")) return;
  await api("/api/reveal", { id: S.question_data[cur].id });
  poll();
};
$("#prev-btn").onclick = () => { if (cur > 0) { cur--; renderExam(); } };
$("#next-btn").onclick = () => { if (cur < S.question_data.length - 1) { cur++; renderExam(); } };
$("#flag-btn").onclick = async () => { await api("/api/flag", { id: S.question_data[cur].id }); poll(); };
$("#end-btn").onclick = async () => {
  const flagged = S.flagged.length ? `\n${S.flagged.length} task(s) are still flagged.` : "";
  if (!confirm("End the exam now and submit for grading?" + flagged)) return;
  await api("/api/finish", {}); poll();
};

function addTerminal() {
  termCount++;
  const id = termCount;
  const f = document.createElement("iframe");
  f.src = TERM_URL; f.dataset.t = id;
  $("#terms").appendChild(f);
  renderTabs(id);
}
function renderTabs(active) {
  const frames = [...document.querySelectorAll("#terms iframe")];
  $("#term-tabs").innerHTML = frames.map(f => `<button data-t="${f.dataset.t}" class="${+f.dataset.t === active ? "active" : ""}">Terminal ${f.dataset.t}</button>`).join("")
    + `<button id="add-term" title="New terminal">+</button>`;
  frames.forEach(f => f.style.visibility = +f.dataset.t === active ? "visible" : "hidden");
  $("#term-tabs").querySelectorAll("button[data-t]").forEach(b => b.onclick = () => renderTabs(+b.dataset.t));
  $("#add-term").onclick = addTerminal;
  const fr = frames.find(f => +f.dataset.t === active); if (fr) setTimeout(() => fr.contentWindow && fr.focus(), 50);
}

// notepad
$("#notes-btn").onclick = () => $("#notes").classList.toggle("hidden");
$("#notes-close").onclick = () => $("#notes").classList.add("hidden");
$("#notes-text").oninput = () => {
  clearTimeout(notesTimer);
  notesTimer = setTimeout(() => api("/api/notes", { notes: $("#notes-text").value }), 600);
};
(function dragNotes() {
  const box = $("#notes"), head = box.querySelector(".notes-head");
  head.onmousedown = (e) => {
    const r = box.getBoundingClientRect(), dx = e.clientX - r.left, dy = e.clientY - r.top;
    const mv = (ev) => { box.style.left = (ev.clientX - dx) + "px"; box.style.top = (ev.clientY - dy) + "px"; box.style.right = "auto"; box.style.bottom = "auto"; };
    const up = () => { document.removeEventListener("mousemove", mv); document.removeEventListener("mouseup", up); };
    document.addEventListener("mousemove", mv); document.addEventListener("mouseup", up);
  };
})();
// resizable split
(function resizer() {
  const r = $("#resizer"), pane = $("#question-pane");
  r.onmousedown = () => {
    document.querySelectorAll("#terms iframe").forEach(f => f.style.pointerEvents = "none");
    const mv = (e) => { pane.style.width = Math.max(280, Math.min(e.clientX, innerWidth - 300)) + "px"; };
    const up = () => { document.querySelectorAll("#terms iframe").forEach(f => f.style.pointerEvents = ""); document.removeEventListener("mousemove", mv); document.removeEventListener("mouseup", up); };
    document.addEventListener("mousemove", mv); document.addEventListener("mouseup", up);
  };
})();

// ---------------------------------------------------------------- results
function renderResults() {
  show("#results");
  const grading = S.status === "grading";
  $("#grading").classList.toggle("hidden", !grading);
  $("#score").classList.toggle("hidden", grading);
  if (grading) {
    $("#grade-bar").style.width = (100 * (S.grading_progress || 0) / S.questions.length) + "%";
    return;
  }
  if ($("#score").dataset.done === String(S.finished_at)) return;
  $("#score").dataset.done = String(S.finished_at);
  $("#score-pct").textContent = S.score_pct + "%";
  $("#score-verdict").innerHTML = S.passed ? `<span class="pass">PASS</span> (passing score 66%)` : `<span class="fail">FAIL</span> (passing score 66%)`;
  const used = Math.round((S.ended_at - S.started_at));
  $("#score-time").textContent = `Time used: ${fmt(used)}`;
  const domains = {};
  const bySection = new Set(S.results.map(r => r.section)).size > 1;
  for (const r of S.results) { const k = bySection ? `S${r.section} ${r.section_title}` : r.domain; const d = domains[k] ||= { w: 0, s: 0 }; d.w += r.weight; d.s += r.score; }
  $("#breakdown").innerHTML = `<tr><th>${bySection ? "Section" : "Domain"}</th><th class="num">Score</th><th class="num">Weight</th><th class="num">%</th></tr>` +
    Object.entries(domains).map(([k, v]) => `<tr><td>${k}</td><td class="num">${v.s.toFixed(1)}</td><td class="num">${v.w}</td><td class="num">${Math.round(100 * v.s / v.w)}%</td></tr>`).join("");
  const rew = new Map();
  for (const r of S.results) if (r.score < r.weight) for (const l of r.lectures || []) rew.set(l.id, l);
  $("#rewatch").classList.toggle("hidden", !rew.size);
  $("#rewatch-list").innerHTML = [...rew.values()].map(l => `<li><a href="${l.url}" target="_blank">S${l.section} · ${l.title}</a></li>`).join("");
  $("#details").innerHTML = S.results.map(r => {
    const full = r.score >= r.weight, zero = r.score === 0;
    return `<details class="qres"><summary>Q${r.q}. ${r.title} — <span class="${full ? "pass" : zero ? "fail" : ""}">${r.score}/${r.weight}</span></summary>
      ${r.checks.map(c => `<div class="check ${c.ok ? "ok" : "no"}">${escapeHtml(c.text)}</div>`).join("") || "<div class='check no'>no checks ran (see state/logs)</div>"}
      ${(r.lectures || []).length ? `<div class="lecs">Lectures: ${r.lectures.map(l => `<a href="${l.url}" target="_blank">${l.title}</a>`).join(" · ")}</div>` : ""}
      <div class="solution md">${marked.parse(r.solution || "")}</div></details>`;
  }).join("");
}
function escapeHtml(s) { return s.replace(/[&<>]/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[c]); }
$("#new-btn").onclick = async () => { await api("/api/reset", {}); termCount = 0; $("#terms").innerHTML = ""; renderedQ = null; poll(); };

// ---------------------------------------------------------------- loop
async function poll() {
  S = await api("/api/state");
  if (S.status === "running") {
    renderExam();
    $("#timer").textContent = fmt(S.remaining);
    $("#timer").classList.toggle("low", S.remaining < 15 * 60);
  } else if (S.status === "grading" || S.status === "finished") {
    renderResults();
  } else {
    renderLobby();
  }
}
let localTick = null;
setInterval(() => {
  if (S && S.status === "running" && S.remaining > 0) { S.remaining--; $("#timer").textContent = fmt(S.remaining); }
}, 1000);
setInterval(poll, 4000);
poll();
