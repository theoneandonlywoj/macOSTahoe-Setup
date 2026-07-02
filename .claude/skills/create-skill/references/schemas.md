# JSON Schemas

All files live in the eval workspace unless noted. Field names matter — the viewer and aggregation scripts rely on them.

## evals.json

Sibling to the skill, inside `<skill-name>-workspace/`.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "The user's task prompt",
      "expected_output": "Description of expected result",
      "files": [],
      "assertions": [
        { "text": "output is valid JSON", "type": "programmatic" },
        { "text": "contains a row for Q4", "type": "programmatic" }
      ]
    }
  ]
}
```

`assertions` may be omitted initially and added while runs are in progress.

## eval_metadata.json

One per eval directory per iteration: `<workspace>/iteration-N/<eval>/eval_metadata.json`.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": [
    { "text": "human-readable description of the check" }
  ]
}
```

Create these fresh each iteration — don't assume carryover.

## timing.json

Per run directory: `<workspace>/iteration-N/<eval>/<config>/timing.json`.

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

Captured from the subagent task notification — process immediately, don't batch.

## grading.json

Per run directory: `<workspace>/iteration-N/<eval>/<config>/grading.json`.

```json
{
  "expectations": [
    {
      "text": "human-readable description of what this assertion checks",
      "passed": true,
      "evidence": "quote from output or script result supporting the verdict"
    }
  ]
}
```

**Field names must be exactly `text`, `passed`, `evidence`** — not `name`/`met`/`details`. The viewer depends on these.

## benchmark.json / benchmark.md

Written by `scripts/aggregate_benchmark.py` into the iteration directory.

```json
{
  "skill_name": "my-skill",
  "iteration": "iteration-1",
  "summary": {
    "with_skill": {
      "pass_rate": { "mean": 0.83, "stddev": 0.05, "n": 3 },
      "tokens":    { "mean": 41200, "stddev": 1800, "n": 3 },
      "duration_ms":{ "mean": 22100, "stddev": 900, "n": 3 }
    },
    "without_skill": { "..." : "..." },
    "delta": { "pass_rate": 0.12 }
  },
  "per_eval": [
    {
      "eval": "descriptive-name",
      "prompt": "...",
      "with_skill":   { "pass_rate": 1.0, "tokens": 41000, "duration_ms": 22000 },
      "without_skill":{ "pass_rate": 0.0, "tokens": 38000, "duration_ms": 21000 }
    }
  ]
}
```

`benchmark.md` is the human-readable rendering of the same data.

## feedback.json

Written by the review viewer (server mode) or downloaded by the user (static mode).

```json
{
  "reviews": [
    { "run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..." }
  ],
  "status": "complete"
}
```

Empty `feedback` = the user thought it was fine. Focus improvements on entries with specific complaints.

## trigger-eval.json (description optimization)

```json
[
  { "query": "the user prompt", "should_trigger": true },
  { "query": "another prompt", "should_trigger": false }
]
```

Queries must be realistic and concrete (file paths, company names, typos, casual speech). Negative cases should be near-misses, not obviously irrelevant.

## description_optimization_report.json

Written by `scripts/run_loop.py`.

```json
{
  "best_description": "the winning description string",
  "best_test_ccr": 0.875,
  "best_iteration": 3,
  "history": [
    { "iteration": 1, "description": "...", "train_ccr": 0.6, "test_ccr": 0.55, "train_trigger_rate": 0.4, "test_trigger_rate": 0.4 }
  ]
}
```

`best_description` is selected by **test** score (held-out 40%) to avoid overfitting to the train split.
