"""Aggregate an iteration directory into benchmark.json + benchmark.md.

Usage:
    python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>

Reads, for each eval directory under <iteration-dir>:
  - eval_metadata.json   (eval_id, eval_name, prompt, assertions)
  - with_skill/grading.json  + with_skill/timing.json
  - <baseline>/grading.json  + <baseline>/timing.json   (baseline = without_skill | old_skill)

Produces, next to the iteration directory:
  - benchmark.json   (per-config pass_rate, time, tokens, mean +/- stddev, delta)
  - benchmark.md     (human-readable summary)

The grading.json expectations array must use fields: text, passed, evidence.
Schema details: references/schemas.md
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
from pathlib import Path

BASELINES = ("without_skill", "old_skill")


def _read_json(p: Path):
    try:
        return json.loads(p.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def _pass_rate(grading):
    if not grading or "expectations" not in grading:
        return None
    exps = grading["expectations"]
    if not exps:
        return None
    passed = sum(1 for e in exps if e.get("passed"))
    return passed / len(exps)


def _timing(t):
    if not t:
        return None, None
    return t.get("total_tokens"), t.get("duration_ms")


def _agg(values):
    vals = [v for v in values if v is not None]
    if not vals:
        return None
    out = {"mean": statistics.fmean(vals), "n": len(vals)}
    if len(vals) > 1:
        out["stddev"] = statistics.pstdev(vals)
    return out


def aggregate(iter_dir: Path, skill_name: str) -> dict:
    eval_dirs = sorted(
        d for d in iter_dir.iterdir() if d.is_dir() and (d / "eval_metadata.json").exists()
    )

    configs = {c: {"pass_rates": [], "tokens": [], "durations": []} for c in ["with_skill", *BASELINES]}
    per_eval = []

    for ed in eval_dirs:
        meta = _read_json(ed / "eval_metadata.json") or {}
        eval_name = meta.get("eval_name", ed.name)
        entry = {"eval": eval_name, "prompt": meta.get("prompt", "")}
        for cfg in ["with_skill", *BASELINES]:
            run = ed / cfg
            grading = _read_json(run / "grading.json")
            timing = _read_json(run / "timing.json")
            pr = _pass_rate(grading)
            toks, dur = _timing(timing)
            entry[cfg] = {"pass_rate": pr, "tokens": toks, "duration_ms": dur}
            if pr is not None:
                configs[cfg]["pass_rates"].append(pr)
            if toks is not None:
                configs[cfg]["tokens"].append(toks)
            if dur is not None:
                configs[cfg]["durations"].append(dur)
        per_eval.append(entry)

    summary = {}
    for cfg, data in configs.items():
        if not data["pass_rates"] and not data["tokens"] and not data["durations"]:
            continue
        summary[cfg] = {
            "pass_rate": _agg(data["pass_rates"]),
            "tokens": _agg(data["tokens"]),
            "duration_ms": _agg(data["durations"]),
        }

    if "with_skill" in summary and "without_skill" in summary:
        ws = summary["with_skill"]
        base = summary["without_skill"]
        if ws.get("pass_rate") and base.get("pass_rate"):
            summary["delta"] = {
                "pass_rate": ws["pass_rate"]["mean"] - base["pass_rate"]["mean"]
            }
    elif "with_skill" in summary and "old_skill" in summary:
        ws = summary["with_skill"]
        base = summary["old_skill"]
        if ws.get("pass_rate") and base.get("pass_rate"):
            summary["delta"] = {
                "pass_rate": ws["pass_rate"]["mean"] - base["pass_rate"]["mean"]
            }

    benchmark = {
        "skill_name": skill_name,
        "iteration": iter_dir.name,
        "summary": summary,
        "per_eval": per_eval,
    }

    out_json = iter_dir / "benchmark.json"
    out_json.write_text(json.dumps(benchmark, indent=2))
    out_md = iter_dir / "benchmark.md"
    out_md.write_text(_render_md(benchmark))
    print(f"wrote {out_json}")
    print(f"wrote {out_md}")
    return benchmark


def _fmt_agg(a):
    if not a:
        return "n/a"
    s = f"{a['mean']:.3f}"
    if "stddev" in a:
        s += f" ± {a['stddev']:.3f}"
    return s + f" (n={a['n']})"


def _render_md(b: dict) -> str:
    lines = [f"# Benchmark — {b['skill_name']} ({b['iteration']})", ""]
    s = b.get("summary", {})
    lines.append("| config | pass_rate | tokens | duration_ms |")
    lines.append("|---|---|---|---|")
    for cfg in ["with_skill", "old_skill", "without_skill"]:
        if cfg not in s:
            continue
        c = s[cfg]
        lines.append(
            f"| {cfg} | {_fmt_agg(c.get('pass_rate'))} | {_fmt_agg(c.get('tokens'))} | {_fmt_agg(c.get('duration_ms'))} |"
        )
    if "delta" in s:
        lines.append("")
        lines.append(f"Delta pass_rate (with_skill - baseline): {s['delta']['pass_rate']:+.3f}")
    lines.append("")
    lines.append("## Per eval")
    lines.append("| eval | with_skill | baseline |")
    lines.append("|---|---|---|")
    for e in b.get("per_eval", []):
        ws = e.get("with_skill", {})
        base = e.get("without_skill") or e.get("old_skill") or {}
        lines.append(
            f"| {e['eval']} | pass={ws.get('pass_rate')} | pass={base.get('pass_rate')} |"
        )
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Aggregate iteration results into benchmark.json/md.")
    ap.add_argument("iter_dir", help="iteration-N directory")
    ap.add_argument("--skill-name", required=True, help="skill name")
    args = ap.parse_args(argv)
    aggregate(Path(args.iter_dir).resolve(), args.skill_name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
