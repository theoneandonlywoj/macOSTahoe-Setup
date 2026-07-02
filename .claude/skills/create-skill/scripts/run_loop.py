"""Optimize a skill's `description` frontmatter for triggering accuracy.

Usage:
    python -m scripts.run_loop \
        --eval-set <trigger-eval.json> \
        --skill-path <path-to-skill> \
        --model <model-id> \
        [--max-iterations 5] [--verbose]

Pipeline:
  1. Split eval set 60% train / 40% held-out test (deterministic by index).
  2. Evaluate current description on train + test (3 runs/query).
  3. Ask claude to propose an improved description from train failures.
  4. Re-evaluate the candidate on train + test.
  5. Repeat up to --max-iterations. Keep the candidate with the best *test*
     score (to avoid overfitting to train).
  6. Write an HTML report and print JSON with `best_description` + scores.

Requires the `claude` CLI (`claude -p`). The skill at --skill-path is mutated
in place between evaluations (the description is swapped); the original is
restored at the end.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

# import run_eval as a module
sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_eval  # noqa: E402


FRONT_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)


def _read_skill(skill_path: Path) -> str:
    return (skill_path / "SKILL.md").read_text()


def _get_description(skill_md: str) -> str:
    m = FRONT_RE.match(skill_md)
    if not m:
        raise SystemExit("SKILL.md has no YAML frontmatter")
    for line in m.group(1).splitlines():
        if line.startswith("description:"):
            val = line[len("description:"):].strip()
            if val.startswith('"') and val.endswith('"'):
                val = val[1:-1]
            return val
    return ""


def _set_description(skill_md: str, new_desc: str) -> str:
    m = FRONT_RE.match(skill_md)
    front = m.group(1)
    rest = skill_md[m.end():]
    new_front = re.sub(
        r"^description:.*$",
        f'description: "{new_desc}"',
        front,
        count=1,
        flags=re.MULTILINE,
    )
    return f"---\n{new_front}\n---\n{rest}"


def _write_skill(skill_path: Path, content: str) -> None:
    (skill_path / "SKILL.md").write_text(content)


def _propose(skill_path: Path, model: str, train_results: list[dict], current: str) -> str:
    """Ask claude to propose an improved description from train failures."""
    if not shutil.which("claude"):
        raise SystemExit("claude CLI not found; cannot propose improvements.")
    failures = [r for r in train_results if (r["trigger_rate"] >= 0.5) != r["should_trigger"]]
    prompt = (
        "You are optimizing the `description` field of a Claude skill so it "
        "triggers at the right times. Here is the current description:\n\n"
        f'"{current}"\n\n'
        "Here are train queries where triggering was wrong "
        "(should_trigger=True means it SHOULD have triggered):\n\n"
        f"{json.dumps(failures, indent=2)}\n\n"
        "Propose ONE improved description string only. It should be a little "
        "'pushy' (Claude tends to undertrigger). Include what the skill does "
        "AND specific contexts for when to use it. Output the new description "
        "on a single line, no quotes, no preamble.\n"
    )
    proc = subprocess.run(
        ["claude", "-p", prompt, "--model", model],
        capture_output=True,
        text=True,
        timeout=120,
    )
    return proc.stdout.strip()


def _split(items: list[dict], train_frac: float = 0.6) -> tuple[list[dict], list[dict]]:
    n = len(items)
    k = max(1, int(round(n * train_frac)))
    return items[:k], items[k:]


def _score(eval_set: list[dict], model: str, skill_path: Path, runs: int, verbose: bool) -> dict:
    return run_eval.evaluate(eval_set, model, skill_path, runs, verbose)


def run_loop(eval_set_path: Path, skill_path: Path, model: str, max_iter: int, verbose: bool) -> dict:
    eval_set = json.loads(eval_set_path.read_text())
    train, test = _split(eval_set)

    original_md = _read_skill(skill_path)
    current_desc = _get_description(original_md)
    history = []

    best = {"description": current_desc, "test_ccr": -1.0, "iteration": 0}

    try:
        for i in range(1, max_iter + 1):
            _write_skill(skill_path, _set_description(original_md, current_desc))
            if verbose:
                print(f"--- iteration {i} ---", file=sys.stderr)
            tr = _score(train, model, skill_path, runs=3, verbose=verbose)
            te = _score(test, model, skill_path, runs=3, verbose=verbose)
            train_ccr = tr["correct_classification_rate"]
            test_ccr = te["correct_classification_rate"]
            history.append(
                {
                    "iteration": i,
                    "description": current_desc,
                    "train_ccr": train_ccr,
                    "test_ccr": test_ccr,
                    "train_trigger_rate": tr["overall_trigger_rate"],
                    "test_trigger_rate": te["overall_trigger_rate"],
                }
            )
            if test_ccr > best["test_ccr"]:
                best = {"description": current_desc, "test_ccr": test_ccr, "iteration": i}
            if verbose:
                print(f"  train_ccr={train_ccr:.3f} test_ccr={test_ccr:.3f}", file=sys.stderr)
            if i < max_iter:
                current_desc = _propose(skill_path, model, tr["results"], current_desc)
    finally:
        _write_skill(skill_path, original_md)

    out = {"best_description": best["description"], "best_test_ccr": best["test_ccr"], "best_iteration": best["iteration"], "history": history}
    report = skill_path.parent / "description_optimization_report.json"
    report.write_text(json.dumps(out, indent=2))
    if verbose:
        print(f"wrote {report}", file=sys.stderr)
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Optimize a skill description for triggering.")
    ap.add_argument("--eval-set", required=True)
    ap.add_argument("--skill-path", required=True)
    ap.add_argument("--model", required=True)
    ap.add_argument("--max-iterations", type=int, default=5)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args(argv)
    out = run_loop(
        Path(args.eval_set).resolve(),
        Path(args.skill_path).resolve(),
        args.model,
        args.max_iterations,
        args.verbose,
    )
    print(json.dumps(out, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
