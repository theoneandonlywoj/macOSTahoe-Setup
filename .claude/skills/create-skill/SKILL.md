---
name: create-skill
description: "Create new Claude skills, modify and improve existing ones, and measure skill performance. Use whenever the user wants to create a skill from scratch, edit or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, optimize a skill's description for better triggering accuracy, or asks 'how do I make a skill' / 'turn this into a skill' / 'improve this skill' — even when they don't explicitly say the word 'skill'. Also use when the user pastes a workflow and wants to capture it as a reusable prompt."
user-invocable: true
disable-model-invocation: false
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Task"]
---

# /create-skill

A skill for creating new skills and iteratively improving them. This skill bundles its own eval toolchain (in `scripts/`, `eval-viewer/`, `agents/`, `references/`, `assets/`) so the full draft → test → review → improve loop is self-contained.

## Skill directory layout

```
create-skill/
├── SKILL.md                 (this file)
├── scripts/
│   ├── aggregate_benchmark.py   # iteration dir -> benchmark.json + benchmark.md
│   ├── run_eval.py              # trigger-rate eval for a description
│   ├── run_loop.py              # description optimization loop
│   └── package_skill.py         # zip skill folder -> .skill file
├── eval-viewer/
│   └── generate_review.py       # review HTML viewer (server or --static)
├── agents/
│   ├── grader.md                # assertion-grading subagent instructions
│   ├── comparator.md            # blind A/B comparison
│   └── analyzer.md              # benchmark-pattern analysis
├── references/
│   └── schemas.md               # JSON schemas for all the files below
└── assets/
    └── eval_review.html         # trigger-eval review template
```

When a script is referenced below as `python -m scripts.foo` or `python eval-viewer/generate_review.py`, run it from this skill's directory (the directory containing this `SKILL.md`). After `make claude-sync` that's `~/.claude/skills/create-skill/`. In the repo it's `./.claude/skills/create-skill/`.

## The core loop

At a high level:

1. Decide what the skill should do and roughly how.
2. Write a draft `SKILL.md`.
3. Write 2–3 realistic test prompts and run them with the skill (and a baseline without it).
4. Help the user evaluate results — qualitatively in the viewer, and quantitatively via benchmarks.
5. Rewrite the skill from feedback. Repeat until satisfied.
6. (Optional) Optimize the `description` for triggering accuracy.
7. Package the final skill.

Your job is to figure out where the user is in this process and jump in. Be flexible — if the user says "just vibe with me", skip the eval machinery.

## Communicating with the user

Users span a wide range of familiarity. Watch context cues. In the default case:
- "evaluation" and "benchmark" are borderline but OK.
- For "JSON" and "assertion", look for cues the user knows them before using them unexplained.
It's fine to briefly explain a term when in doubt.

## Step 1 — Capture intent

If the conversation already contains a workflow to capture ("turn this into a skill"), extract from history first — tools used, step sequence, corrections, input/output formats — then have the user fill gaps. Confirm before proceeding. Ask:

1. What should this skill enable Claude to do?
2. When should it trigger? (user phrases / contexts)
3. Expected output format?
4. Set up test cases? Skills with objectively verifiable outputs (file transforms, codegen, fixed workflows) benefit from test cases. Subjective outputs (writing style, art) often don't. Suggest the right default, but let the user decide.

## Step 2 — Interview and research

Proactively ask about edge cases, input/output formats, example files, success criteria, dependencies. Don't write test prompts until this is ironed out. Use subagents (Task) in parallel to research docs / similar skills / best practices.

## Step 3 — Write the SKILL.md

Fill in:
- **name**: skill identifier.
- **description**: when to trigger + what it does. This is the **primary** triggering mechanism — include both what the skill does AND specific contexts for when to use it. All "when to use" info goes here, not in the body. Claude tends to undertrigger skills, so make descriptions a little **pushy**: instead of "build a dashboard", write "build a dashboard; use this whenever the user mentions dashboards, data visualization, internal metrics, or wants to display company data — even if they don't say 'dashboard'.".
- **compatibility**: required tools/dependencies (optional, rarely needed).
- **the body**: the instructions.

### Skill writing guide

Anatomy:
```
skill-name/
├── SKILL.md            (required: YAML frontmatter + Markdown)
└── (optional) scripts/ references/ assets/
```

Progressive disclosure (three levels):
1. Metadata (name + description) — always in context (~100 words).
2. SKILL.md body — in context when the skill triggers (<500 lines ideal).
3. Bundled resources — as needed (unlimited; scripts can execute without loading).

Key patterns:
- Keep SKILL.md under ~500 lines. Approaching the limit? Add a hierarchy layer with clear pointers to where the model should go next.
- Reference files clearly, with guidance on when to read them.
- For large reference files (>300 lines), include a table of contents.
- Domain organization: when a skill supports multiple variants, organize by variant and read only the relevant one.

Principle of no surprise: skills must not contain malware or facilitate unauthorized access. Don't create misleading skills.

Prefer **imperative** form in instructions.

Defining output formats:
```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

Examples pattern:
```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

Writing style: explain **why** things matter instead of heavy-handed MUSTs. Use theory of mind; make the skill general, not narrow to specific examples. Draft, then reread with fresh eyes and improve.

## Step 4 — Test cases

After the draft, come up with 2–3 realistic test prompts — what a real user would say. Share them: "Here are a few test cases I'd like to try. Do these look right, or add more?" Then run them.

Save to `evals/evals.json` (sibling to the skill directory, inside a `<skill-name>-workspace/`):
```json
{
  "skill_name": "example-skill",
  "evals": [
    { "id": 1, "prompt": "...", "expected_output": "...", "files": [] }
  ]
}
```
Don't write assertions yet — you'll draft them while runs are in progress. Full schema in `references/schemas.md`.

## Step 5 — Run and evaluate

One continuous sequence — don't stop partway. Do NOT use any other testing skill.

Workspace layout: `<skill-name>-workspace/` as a sibling to the skill directory. Organize by iteration (`iteration-1/`, `iteration-2/` …) and within that, one directory per test case (`eval-0/` …). Create directories as you go.

### 5.1 Spawn all runs (with-skill AND baseline) in the same turn

For each test case, spawn two subagents in the **same turn** — one with the skill, one without. Launch everything at once so it finishes together.

**With-skill run:**
```
Execute this task:
- Skill path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user cares about>
```

**Baseline run** (depends on context):
- Creating a new skill → no skill at all. Same prompt, no skill path, save to `without_skill/outputs/`.
- Improving an existing skill → snapshot the old version first (`cp -r <skill-path> <workspace>/skill-snapshot/`), point the baseline at the snapshot, save to `old_skill/outputs/`.

Write an `eval_metadata.json` per test case (assertions empty for now). Use a descriptive directory name (not just `eval-0`). Create these files per new eval dir each iteration — don't assume carryover.
```json
{ "eval_id": 0, "eval_name": "descriptive-name", "prompt": "...", "assertions": [] }
```

### 5.2 While runs progress, draft assertions

Don't just wait. Draft quantitative assertions per test case; explain them to the user. If assertions already exist, review and explain them. Good assertions are objectively verifiable with descriptive names that read clearly in the viewer. Subjective skills are better evaluated qualitatively — don't force assertions. Update `eval_metadata.json` and `evals/evals.json`.

### 5.3 Capture timing as runs complete

Each subagent task notification carries `total_tokens` and `duration_ms`. Save immediately to `timing.json` in the run directory:
```json
{ "total_tokens": 84852, "duration_ms": 23332, "total_duration_seconds": 23.3 }
```
This data only arrives via the notification — process each as it arrives, don't batch.

### 5.4 Grade, aggregate, analyze, launch viewer

1. **Grade each run** — spawn a grader subagent that reads `agents/grader.md` and evaluates each assertion against outputs. Save to `grading.json` per run dir. The `expectations` array **must** use fields `text`, `passed`, `evidence` (not `name`/`met`/`details`) — the viewer depends on these exact names. For programmatically-checkable assertions, write and run a script rather than eyeballing.

2. **Aggregate** — from this skill's directory:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   Produces `benchmark.json` and `benchmark.md` (pass_rate, time, tokens per config, mean ± stddev, delta). Put each `with_skill` version before its baseline counterpart. Schema in `references/schemas.md`.

3. **Analyst pass** — read the benchmark and surface patterns the aggregates hide. See `agents/analyzer.md`: non-discriminating assertions (always pass regardless of skill), high-variance/flaky evals, time/token tradeoffs.

4. **Launch the viewer**:
   ```bash
   nohup python eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   VIEWER_PID=$!
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.
   Headless / no-display: pass `--static <output_path>` to write a standalone HTML file instead of starting a server. Feedback is downloaded as `feedback.json` when the user clicks "Submit All Reviews"; copy it into the workspace for the next iteration. Use `generate_review.py` — don't write custom HTML.

5. **Tell the user**: "I've opened the results in your browser. 'Outputs' lets you click through each test case and leave feedback; 'Benchmark' shows the quantitative comparison. Come back when done."

### What the user sees

**Outputs tab** (one case at a time): Prompt; Output (rendered inline); Previous Output (iter 2+, collapsed); Formal Grades (if graded, collapsed); Feedback textbox (auto-saves); Previous Feedback (iter 2+, below the textbox).
**Benchmark tab**: pass rates, timing, tokens per config, per-eval breakdowns, analyst observations.
Navigation: prev/next or arrow keys. "Submit All Reviews" saves `feedback.json`.

### 5.5 Read the feedback

When the user says they're done, read `feedback.json`:
```json
{
  "reviews": [
    { "run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..." }
  ],
  "status": "complete"
}
```
Empty feedback = fine. Focus improvements on cases with specific complaints. Kill the viewer: `kill $VIEWER_PID 2>/dev/null`.

## Step 6 — Improve the skill

Heart of the loop. How to think about improvements:

1. **Generalize from feedback.** We're building skills used many times across many prompts. Don't add fiddly overfitty changes or oppressive MUSTs. If an issue is stubborn, try different metaphors or working patterns.
2. **Keep the prompt lean.** Remove what isn't pulling its weight. Read transcripts, not just outputs — if the skill makes the model waste time on unproductive steps, cut those parts.
3. **Explain the why.** LLMs are smart; give them the reasoning and they generalize. Even terse/frustrated feedback has a real intent behind it — understand it and transmit that understanding. If you catch yourself writing ALWAYS/NEVER in caps, that's a yellow flag — reframe with reasoning.
4. **Look for repeated work across test cases.** If all runs independently wrote similar helper scripts, bundle it into `scripts/` once and tell the skill to use it.

Take your time mulling it over. Draft a revision, reread with fresh eyes, improve.

### Iteration loop

After improving: apply changes → rerun all test cases into `iteration-<N+1>/` (including baselines; for new skills the baseline is always `without_skill`) → launch reviewer with `--previous-workspace` → wait for review → read feedback → improve → repeat. Stop when the user is happy, feedback is all empty, or you're not making meaningful progress.

## Advanced — Blind comparison

For rigorous A/B ("is the new version actually better?"), read `agents/comparator.md` and `agents/analyzer.md`: give two outputs to an independent agent without labels, let it judge, then analyze why the winner won. Optional, requires subagents. Human review is usually sufficient.

## Step 7 — Description optimization

The `description` field drives whether Claude invokes the skill. After the skill is done, offer to optimize it. Detail in `references/schemas.md`; summary:

1. Generate 20 trigger eval queries (mix of should-trigger / should-not-trigger), realistic and concrete (file paths, company names, typos, casual speech). Negatives should be near-misses, not obviously irrelevant. Save as JSON.
2. Review with user via `assets/eval_review.html` (replace `__EVAL_DATA_PLACEHOLDER__`, `__SKILL_NAME_PLACEHOLDER__`, `__SKILL_DESCRIPTION_PLACEHOLDER__`; write to `/tmp/eval_review_<name>.html`; `open` it; user exports `~/Downloads/eval_set.json`).
3. Run the loop in the background:
   ```bash
   python -m scripts.run_loop \
     --eval-set <trigger-eval.json> \
     --skill-path <path-to-skill> \
     --model <model-id-powering-this-session> \
     --max-iterations 5 \
     --verbose
   ```
   Use the current session's model ID. It splits 60/40 train/held-out test, evaluates 3× per query, proposes improvements, re-evaluates, iterates ≤5 times, opens an HTML report, returns JSON with `best_description` (selected by test score to avoid overfitting).
4. Apply `best_description` to the SKILL.md frontmatter. Show before/after + scores.

Triggering note: Claude only consults skills for tasks it can't easily handle alone — simple one-step queries ("read file X") won't trigger regardless of description quality. Make eval queries substantive.

## Environments without subagents / browser

- **No subagents**: run test cases yourself one at a time (read SKILL.md, follow it for the prompt). Skip baselines and quantitative benchmarking; focus on qualitative feedback. Organize into iteration dirs if you have a filesystem.
- **No browser**: present results inline (prompt + output; save file outputs and tell the user where). Ask for feedback inline.
- **Description optimization** needs `claude -p` — skip if unavailable.

## Updating an existing skill

- Preserve the original name (directory name + `name` frontmatter).
- Copy to a writable location (`/tmp/skill-name/`) before editing if the installed path is read-only.
- Stage in `/tmp/` before copying to the output dir if permissions are tight.

## Packaging

```bash
python -m scripts.package_skill <path/to/skill-folder>
```
Direct the user to the resulting `.skill` file.

## Reference files

- `agents/grader.md` — how to evaluate assertions against outputs.
- `agents/comparator.md` — blind A/B comparison.
- `agents/analyzer.md` — why one version beat another.
- `references/schemas.md` — JSON structures for `evals.json`, `grading.json`, `benchmark.json`, `eval_metadata.json`, `timing.json`, `feedback.json`.

## Checklist for every iteration

- [ ] Skill draft written and under ~500 lines
- [ ] `evals/evals.json` with 2–3 realistic prompts
- [ ] With-skill + baseline runs spawned in the same turn
- [ ] `eval_metadata.json` per test case with assertions
- [ ] `timing.json` captured from each task notification
- [ ] `grading.json` per run (fields `text`/`passed`/`evidence`)
- [ ] `benchmark.json` + `benchmark.md` via `aggregate_benchmark.py`
- [ ] Viewer launched via `generate_review.py` (before self-evaluating)
- [ ] `feedback.json` read and improvements applied
