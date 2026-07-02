"""Evaluate a skill description's trigger rate via `claude -p`.

Usage:
    python -m scripts.run_eval \
        --eval-set <trigger-eval.json> \
        --skill-path <path-to-skill> \
        --model <model-id> \
        [--runs 3] [--verbose]

`trigger-eval.json` schema:
    [{"query": "...", "should_trigger": true}, ...]

For each query, runs `claude -p "<query>" --output-format stream-json --model <model>`
`--runs` times and detects whether the skill was consulted. The skill at
`--skill-path` must already contain the candidate description (run_loop.py swaps
descriptions between evaluations).

Detection: parses stream-json events and looks for a Skill tool_use whose `name`
field matches the skill, or falls back to a substring match on the skill name in
the assembled text. This is a best-effort heuristic — tune `detect_invocation`
if your environment emits a different event shape.

Output JSON to stdout:
    {"results": [{"query":..., "should_trigger":..., "triggered_runs":k, "runs":n, "trigger_rate":k/n}],
     "overall_trigger_rate": float, "correct_classification_rate": float}
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


def _skill_name(skill_path: Path) -> str:
    return skill_path.name


def _run_once(query: str, model: str, skill_name: str) -> bool:
    """Run claude -p once and return whether the skill was invoked."""
    if not shutil.which("claude"):
        raise SystemExit("claude CLI not found in PATH; description optimization requires `claude -p`.")
    cmd = ["claude", "-p", query, "--output-format", "stream-json", "--model", model]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:
        return False
    return _detect_invocation(proc.stdout, skill_name)


def _detect_invocation(stream_json: str, skill_name: str) -> bool:
    """Inspect stream-json output for evidence the skill was consulted."""
    needle = skill_name.lower()
    for line in stream_json.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            evt = json.loads(line)
        except json.JSONDecodeError:
            continue
        # Tool use events: look for a Skill tool call mentioning the skill name.
        msg = evt.get("message") or evt
        content = msg.get("content") if isinstance(msg, dict) else None
        if isinstance(content, list):
            for block in content:
                if not isinstance(block, dict):
                    continue
                if block.get("type") == "tool_use":
                    name = (block.get("name") or "")
                    inp = json.dumps(block.get("input", {})).lower()
                    if "skill" in name.lower() and needle in inp:
                        return True
        # Fallback: substring match anywhere in the event text.
        if needle in json.dumps(evt).lower():
            return True
    return False


def evaluate(eval_set: list[dict], model: str, skill_path: Path, runs: int, verbose: bool) -> dict:
    skill_name = _skill_name(skill_path)
    results = []
    correct = 0
    for item in eval_set:
        q = item["query"]
        expected = bool(item["should_trigger"])
        hits = sum(1 for _ in range(runs) if _run_once(q, model, skill_name))
        rate = hits / runs
        predicted = rate >= 0.5
        if predicted == expected:
            correct += 1
        if verbose:
            print(f"  [{ 'TRIG' if expected else 'no-trig' }] hits={hits}/{runs} q={q[:60]!r}", file=sys.stderr)
        results.append(
            {
                "query": q,
                "should_trigger": expected,
                "triggered_runs": hits,
                "runs": runs,
                "trigger_rate": rate,
            }
        )
    overall = sum(r["trigger_rate"] for r in results) / len(results) if results else 0.0
    ccr = correct / len(eval_set) if eval_set else 0.0
    return {"results": results, "overall_trigger_rate": overall, "correct_classification_rate": ccr}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Evaluate skill description trigger rate via claude -p.")
    ap.add_argument("--eval-set", required=True, help="path to trigger-eval.json")
    ap.add_argument("--skill-path", required=True, help="path to the skill folder")
    ap.add_argument("--model", required=True, help="model id powering the session")
    ap.add_argument("--runs", type=int, default=3, help="runs per query (default 3)")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args(argv)

    eval_set = json.loads(Path(args.eval_set).read_text())
    out = evaluate(eval_set, args.model, Path(args.skill_path).resolve(), args.runs, args.verbose)
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
