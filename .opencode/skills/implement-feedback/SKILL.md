---
name: implement-feedback
description: Use when a user invokes /implement-feedback, or asks to "implement the feedback", "address the review comments", "fix the PR comments", or similar. Reads the agreed feedback note from _woj/11-feedback/NNN-<slug>.md (written by investigate-feedback, which is never modified), implements every fix item following repo conventions, re-runs tests/lint until green, and writes its own implementation note to _woj/12-implement-feedback/NNN-<slug>.md mirroring the feedback note's basename. Routes the outcome to /workflow-visualization when any item has workflow impact, otherwise to /code-quality.
---

# Implement Feedback

Implement the agreed PR feedback fixes recorded in the feedback note under `_woj/11-feedback/`, verify the work with tests/lint, and record the results in a handoff note under `_woj/12-implement-feedback/` so the next step in the feature workflow can pick up from disk. The feedback note is **read-only** for this skill — it is the input, never the output.

## When to use

- The user invokes `/implement-feedback`.
- The user asks to "implement the feedback", "address the review comments", "fix the PR comments", "apply the review findings", or similar phrasing.
- The user passes a file path to an existing feedback note (e.g. `/implement-feedback _woj/11-feedback/002-...md`), naming the note whose decisions should be implemented.

## Mode selection

At the start, inspect the first argument:

- If it names a file (absolute, repo-root-relative, or `_woj/11-feedback/`-relative path to a `NNN-<slug>.md` note), use that note as the input.
- If it names a file that does **not** exist, report an error and stop — never create a note from an implementation invocation.
- If no argument is given, use the note with the highest `NNN-` prefix in `_woj/11-feedback/` (the latest feedback).
- If `_woj/11-feedback/` does not exist or is empty, report that no feedback is being tracked and stop.

## Workflow

### 1. Read the feedback note

Read the chosen note in full. It was written by `investigate-feedback` and contains:

- `## Source` — the original review/PR comments.
- `### Item <n>` blocks — each carries a **Decision** (`fix` | `won't-fix` | `needs-discussion`), an **Action** describing the agreed change, and a **Workflow impact** flag (yes/no).
- `## Summary` — the overall picture of the review.

Also read the spec note with the same basename in `_woj/05-spec/` (e.g. feedback `_woj/11-feedback/002-setup-logging.md` pairs with `_woj/05-spec/002-setup-logging.md`) when it exists, to recover the feature's intent where the Action text is terse.

### 2. Classify the items

- **`fix`** — implement the change, following repo conventions (`*.zsh` script pattern, Makefile targets, error-handling style). See `AGENTS.md`, `README.md`, and the `Makefile` before writing code.
- **`won't-fix`** — do NOT change code; record it as-is in the results.
- **`needs-discussion`** — do NOT change code; record it and carry it forward as `needs-discussion`.

### 3. Implement the `fix` items

- Work through the items one at a time, in order. Keep changes scoped to what each Action asks for.
- Follow the same conventions as the surrounding code; cite concrete `file:line` references for every change.
- After implementation, re-run the project's tests/lint per `README.md`/`Makefile` (e.g. `make test`, `make lint`) until everything passes. Record the exact commands run and their results.

### 4. Write the implementation note

Write to `_woj/12-implement-feedback/NNN-<slug>.md` where:

- `NNN` and `<slug>` **mirror the feedback note's basename** (e.g. feedback note `_woj/11-feedback/002-setup-logging.md` produces `_woj/12-implement-feedback/002-setup-logging.md`), making the chain traceable: PR -> feedback -> implementation.
- Create `_woj/12-implement-feedback/` if it does not exist. Never overwrite an existing file.
- If a note with the mirrored basename already exists (a later review round), append a new `## Round <n>` section — continuing the round numbering — with the new `## Results` and `## Route` content, preserving the earlier rounds.

Note template:

    # <Short feature title> — Feedback Implementation

    ## Source

    Feedback note: `_woj/11-feedback/NNN-<slug>.md`

    ## Results

    - **Item <n>:** resolved | needs-discussion — <what was changed, with `file:line`; or why it was not changed for `won't-fix`/`needs-discussion`> — tests/lint: `<commands run>` → `<results>`

    ## Route

    - <`/workflow-visualization` because item(s) had workflow impact, or `/code-quality` for re-review>

Use `resolved` for implemented `fix` items and for `won't-fix` items (decision honored, no change needed); use `needs-discussion` for items carried forward. For `won't-fix` and `needs-discussion` items, note explicitly that no code was changed.

### 5. Route the outcome

- If **any** item had **Workflow impact: yes**, the next step is `/workflow-visualization` — pass it the implementation note path so it can mirror the basename (update `_workflow.md` to reflect the process change).
- Otherwise, the next step is `/code-quality` for re-review of the changed code.

The `## Route` section records which route was taken; always include it — it is the handoff to the next step.

## Verify before finishing

- Re-read the implementation note and confirm the filename mirrors the feedback note (`NNN-<slug>.md`).
- Confirm the feedback note under `_woj/11-feedback/` is byte-for-byte unchanged — this skill never modifies its input.
- Confirm every `fix` item is either `resolved` with evidence (what changed, `file:line`, passing tests/lint) or explicitly carried as `needs-discussion`.
- Confirm the bullets' item numbers match the `### Item <n>` blocks in the feedback note.
- In a repeated round, confirm only the new `## Round <n>` section was added and earlier rounds are untouched.

## Reporting back

Tell the user:

- The full path of the implementation note written.
- Per-item results: each item number with `resolved` or `needs-discussion` and the key change (or why nothing changed).
- The tests/lint commands run and whether they passed.
- The route taken: `/workflow-visualization` (if any workflow impact) or `/code-quality` (re-review).
