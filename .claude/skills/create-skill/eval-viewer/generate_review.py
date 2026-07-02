"""Review viewer for skill eval results.

Usage:
    # server mode (opens a browser tab)
    python eval-viewer/generate_review.py <workspace>/iteration-N \
        --skill-name "my-skill" \
        --benchmark <workspace>/iteration-N/benchmark.json

    # headless / no-display
    python eval-viewer/generate_review.py <workspace>/iteration-N \
        --skill-name "my-skill" \
        --benchmark <workspace>/iteration-N/benchmark.json \
        --static <output.html>

    # iteration 2+
    ... --previous-workspace <workspace>/iteration-<N-1>

The Outputs tab shows one test case at a time: prompt, rendered outputs,
formal grades (collapsed), previous output (collapsed, iter 2+), and a
feedback textbox. The Benchmark tab shows the quantitative summary.

In server mode, "Submit All Reviews" POSTs to the server and writes
feedback.json next to the iteration dir. In --static mode, the button
downloads feedback.json via a JS Blob.
"""

from __future__ import annotations

import argparse
import html
import json
import sys
import threading
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

BASELINES = ("without_skill", "old_skill")


def _read_json(p: Path):
    try:
        return json.loads(p.read_text())
    except Exception:
        return None


def _read_text(p: Path):
    try:
        return p.read_text(errors="replace")
    except Exception:
        return ""


def _read_output_files(run_dir: Path) -> list[dict]:
    out = run_dir / "outputs"
    files = []
    if out.is_dir():
        for p in sorted(out.iterdir()):
            if p.is_file():
                files.append({"name": p.name, "content": _read_text(p)})
    return files


def _gather_cases(iter_dir: Path, previous_dir: Path | None) -> list[dict]:
    cases = []
    for ed in sorted(d for d in iter_dir.iterdir() if d.is_dir() and (d / "eval_metadata.json").exists()):
        meta = _read_json(ed / "eval_metadata.json") or {}
        case = {
            "eval_id": meta.get("eval_id", ed.name),
            "eval_name": meta.get("eval_name", ed.name),
            "prompt": meta.get("prompt", ""),
            "assertions": meta.get("assertions", []),
            "runs": {},
            "previous": None,
        }
        for cfg in ["with_skill", *BASELINES]:
            run = ed / cfg
            if run.is_dir():
                grading = _read_json(run / "grading.json") or {}
                timing = _read_json(run / "timing.json") or {}
                case["runs"][cfg] = {
                    "outputs": _read_output_files(run),
                    "expectations": grading.get("expectations", []),
                    "timing": timing,
                }
        if previous_dir:
            prev = previous_dir / ed.name / "with_skill"
            if prev.is_dir():
                case["previous"] = {"outputs": _read_output_files(prev)}
        cases.append(case)
    return cases


def _render_outputs_tab(cases: list[dict]) -> str:
    if not cases:
        return "<p>No test cases found.</p>"
    blocks = []
    for i, c in enumerate(cases):
        runs = c["runs"]
        ws = runs.get("with_skill", {})
        base = runs.get("without_skill") or runs.get("old_skill") or {}
        blocks.append(f'<div class="case" id="case-{i}" style="display:{ "block" if i == 0 else "none"}">')
        blocks.append(f'<h3>{html.escape(str(c["eval_name"]))}</h3>')
        blocks.append(f'<div class="prompt"><b>Prompt</b><pre>{html.escape(c["prompt"])}</pre></div>')

        if c["assertions"]:
            blocks.append("<details><summary>Assertions</summary><ul>")
            for a in c["assertions"]:
                blocks.append(f"<li>{html.escape(str(a))}</li>")
            blocks.append("</ul></details>")

        blocks.append('<div class="outputs"><b>Output (with_skill)</b>')
        for f in ws.get("outputs", []):
            blocks.append(f'<div class="outfile"><i>{html.escape(f["name"])}</i><pre>{html.escape(f["content"])}</pre></div>')
        blocks.append("</div>")

        if c["previous"]:
            blocks.append("<details><summary>Previous output</summary>")
            for f in c["previous"]["outputs"]:
                blocks.append(f'<div class="outfile"><i>{html.escape(f["name"])}</i><pre>{html.escape(f["content"])}</pre></div>')
            blocks.append("</details>")

        if ws.get("expectations"):
            blocks.append("<details><summary>Formal grades</summary><table><tr><th>assertion</th><th>passed</th></tr>")
            for e in ws["expectations"]:
                mark = "✅" if e.get("passed") else "❌"
                blocks.append(f"<tr><td>{html.escape(str(e.get('text','')))}</td><td>{mark}</td></tr>")
            blocks.append("</table></details>")

        blocks.append(f'<div class="feedback"><b>Feedback</b><textarea data-run-id="eval-{i}-with_skill" rows="4" style="width:100%"></textarea></div>')

        if base:
            blocks.append("<details><summary>Baseline output</summary>")
            for f in base.get("outputs", []):
                blocks.append(f'<div class="outfile"><i>{html.escape(f["name"])}</i><pre>{html.escape(f["content"])}</pre></div>')
            blocks.append("</details>")

        blocks.append("</div>")
    nav = (
        '<div class="nav"><button onclick="prevCase()">◀ Prev</button> '
        '<span id="case-counter"></span> '
        '<button onclick="nextCase()">Next ▶</button></div>'
    )
    return nav + "\n".join(blocks)


def _render_benchmark_tab(benchmark: dict | None) -> str:
    if not benchmark:
        return "<p>No benchmark data.</p>"
    s = benchmark.get("summary", {})
    rows = []
    for cfg in ["with_skill", "old_skill", "without_skill"]:
        if cfg not in s:
            continue
        c = s[cfg]
        pr = c.get("pass_rate") or {}
        tk = c.get("tokens") or {}
        dur = c.get("duration_ms") or {}
        rows.append(
            f"<tr><td>{cfg}</td><td>{pr.get('mean','n/a')}</td><td>{tk.get('mean','n/a')}</td><td>{dur.get('mean','n/a')}</td></tr>"
        )
    table = "<table><tr><th>config</th><th>pass_rate</th><th>tokens</th><th>duration_ms</th></tr>" + "".join(rows) + "</table>"
    per = "<details><summary>Per eval</summary><table><tr><th>eval</th><th>with_skill pass</th><th>baseline pass</th></tr>"
    for e in benchmark.get("per_eval", []):
        ws = e.get("with_skill", {})
        base = e.get("without_skill") or e.get("old_skill") or {}
        per += f"<tr><td>{html.escape(str(e.get('eval','')))}</td><td>{ws.get('pass_rate')}</td><td>{base.get('pass_rate')}</td></tr>"
    per += "</table></details>"
    return f"<h3>Benchmark — {html.escape(benchmark.get('skill_name',''))}</h3>{table}{per}"


def build_html(cases: list[dict], benchmark: dict | None, skill_name: str, static: bool) -> str:
    outputs_html = _render_outputs_tab(cases)
    bench_html = _render_benchmark_tab(benchmark)
    submit_js = "submitStatic()" if static else "submitServer()"
    return f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Skill review — {html.escape(skill_name)}</title>
<style>
body {{ font-family: -apple-system, sans-serif; margin: 1.5rem; }}
.tabs button {{ padding: .4rem .8rem; cursor: pointer; }}
.tabpane {{ display: none; }} .tabpane.active {{ display: block; }}
pre {{ background: #f4f4f4; padding: .5rem; overflow:auto; white-space: pre-wrap; }}
table {{ border-collapse: collapse; }} td,th {{ border:1px solid #ccc; padding:.3rem .5rem; }}
.nav button {{ padding:.3rem .6rem; }} .case {{ border-top: 1px solid #eee; padding-top:1rem; }}
details {{ margin: .5rem 0; }}
</style></head><body>
<h2>Skill review — {html.escape(skill_name)}</h2>
<div class="tabs">
  <button onclick="showTab('outputs')">Outputs</button>
  <button onclick="showTab('benchmark')">Benchmark</button>
</div>
<div id="outputs" class="tabpane active">{outputs_html}</div>
<div id="benchmark" class="tabpane">{bench_html}</div>
<button onclick="{submit_js}" style="margin-top:1rem">Submit All Reviews</button>
<div id="status"></div>
<script>
let idx = 0; const cases = Array.from(document.querySelectorAll('.case'));
function showTab(t) {{ document.querySelectorAll('.tabpane').forEach(p=>p.classList.remove('active')); document.getElementById(t).classList.add('active'); }}
function showCase() {{ cases.forEach((c,i)=>c.style.display = (i===idx?'block':'none')); document.getElementById('case-counter').textContent = (idx+1)+' / '+cases.length; }}
function nextCase() {{ if(idx<cases.length-1){{idx++; showCase();}} }}
function prevCase() {{ if(idx>0){{idx--; showCase();}} }}
showCase();
function collectFeedback() {{ return Array.from(document.querySelectorAll('textarea[data-run-id]')).map(t=>({{run_id:t.dataset.runId, feedback:t.value}})); }}
function submitServer() {{
  fetch('/feedback', {{method:'POST', body:JSON.stringify({{reviews:collectFeedback(), status:'complete'}})}})
   .then(r=>r.text()).then(t=>document.getElementById('status').textContent='Saved: '+t)
   .catch(e=>document.getElementById('status').textContent='Error: '+e);
}}
function submitStatic() {{
  const data = JSON.stringify({{reviews:collectFeedback(), status:'complete'}}, null, 2);
  const blob = new Blob([data], {{type:'application/json'}});
  const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = 'feedback.json'; a.click();
  document.getElementById('status').textContent = 'Downloaded feedback.json';
}}
</script></body></html>"""


class Handler(BaseHTTPRequestHandler):
    html_payload = ""
    iter_dir: Path | None = None

    def log_message(self, *a):
        pass

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(self.html_payload.encode())

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            data = {"reviews": [], "status": "complete"}
        if self.iter_dir is not None:
            (self.iter_dir / "feedback.json").write_text(json.dumps(data, indent=2))
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"ok")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Generate the skill review viewer.")
    ap.add_argument("iter_dir")
    ap.add_argument("--skill-name", required=True)
    ap.add_argument("--benchmark", default=None)
    ap.add_argument("--previous-workspace", default=None)
    ap.add_argument("--static", default=None, help="write standalone HTML to this path instead of starting a server")
    ap.add_argument("--port", type=int, default=8765)
    args = ap.parse_args(argv)

    iter_dir = Path(args.iter_dir).resolve()
    prev = Path(args.previous_workspace).resolve() if args.previous_workspace else None
    benchmark = _read_json(Path(args.benchmark)) if args.benchmark else None
    cases = _gather_cases(iter_dir, prev)
    payload = build_html(cases, benchmark, args.skill_name, static=bool(args.static))

    if args.static:
        Path(args.static).write_text(payload)
        print(f"wrote {args.static}")
        return 0

    Handler.html_payload = payload
    Handler.iter_dir = iter_dir
    httpd = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    url = f"http://127.0.0.1:{args.port}/"
    threading.Timer(0.5, lambda: webbrowser.open(url)).start()
    print(f"serving review viewer at {url} (Ctrl-C to stop)")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
