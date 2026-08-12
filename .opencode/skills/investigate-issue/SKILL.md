---
name: investigate-issue
description: Use when a user invokes /investigate-issue, or asks to "investigate this bug", "find the root cause", "diagnose this issue", "debug this problem", or similar. Investigates a bug in the bug path of the feature workflow: resolves the source ticket from _woj/00-tickets/ (or a raw bug report when no ticket exists), reproduces the failure, traces the root cause in the codebase (Graphify first when the knowledge graph exists), and writes a structured issue note to _woj/00-issues/NNN-<slug>.md with reproduction steps, root cause with file:line references, impact, proposed fix, assumptions, and open questions. Also use when a path to an existing 00-issues note is passed (update mode): append a Conclusions section to that note.
---

# Investigate Issue

Investigate a bug in the bug path of the feature workflow: reproduce the failure, find the root cause in the codebase, and propose a fix. The investigation is grounded in the source ticket from `_woj/00-tickets/` (or a raw bug report when no ticket exists) and its findings are handed off in a structured issue note under `_woj/00-issues/`. Use Graphify first whenever the knowledge graph is available; fall back to direct codebase exploration otherwise.

## When to use

- The user invokes `/investigate-issue`.
- The user asks to "investigate this bug", "find the root cause", "diagnose this issue", "debug this problem", "figure out why X fails", or similar phrasing.
- The user passes a file path to an existing issue note (e.g. `/investigate-issue _woj/00-issues/002-...md <conclusions>`), or asks to "update the issue note with conclusions", "append conclusions". This is **update mode** — see "Workflow (update mode)".

Always review `AGENTS.md` (if present) for knowledge-graph rules before investigating, regardless of mode.

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/00-issues/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default). The bug to investigate is the named ticket, the latest ticket (highest `NNN-` prefix) in `_woj/00-tickets/`, or a raw bug report when no ticket exists.

## Workflow (create mode)

### 1. Resolve the input

- If the user named a ticket path, use it.
- Otherwise, scan `_woj/00-tickets/*.md` and use the ticket with the highest `NNN-` prefix (the latest ticket). Read the chosen ticket in full: `Source`, `Type`, `Description`, `Acceptance criteria`, `Assumptions`, and `Open questions` tell you what failure is reported, in which environment, and what success looks like.
- If no ticket exists, accept the raw bug report from the user's message as the source, and **flag the missing ticket** in the note and in the report back.
- If the ticket is not a bug (e.g. `Type` is not a bug/defect), proceed anyway but note the mismatch in `## Assumptions`.

### 2. Reproduce the bug

- Derive concrete, ordered reproduction steps from the report and the ticket's `Description`.
- Where safe, run the relevant scripts or commands to confirm the failure — this repo is full of `*.zsh` setup scripts, so reproduction often means executing a script or a Makefile target. Skip anything destructive (e.g. wiping config, installing system-wide) and note the skipped step.
- Record the **observed behavior** (what actually happened) and the **expected behavior** (what should have happened, per the ticket's `Acceptance criteria` if present).

### 3. Investigate the root cause

Check that Graphify is available: the `graphify` binary is on PATH (`which graphify`) and `graphify-out/graph.json` exists (per `AGENTS.md`). If either is missing, go to step 4.

- Drive the investigation with focused Graphify commands rather than grepping raw files:
  - `graphify query "<question>"` — fetch a scoped subgraph around the failing component.
  - `graphify path "<A>" "<B>"` — find relationships between the failure point and its callers/callees.
  - `graphify explain "<concept>"` — plain-language explanation of a node.
- If `graphify-out/wiki/index.md` exists, use it for broad navigation before raw source browsing.
- Use the surfaced subgraph to decide which source files to open next; prefer the returned `src=... loc=L<line>` references for precise navigation.
- Open the surfaced files and line ranges, read the relevant code, and trace the failure from symptom to cause.
- **Record concrete `file:line` references for everything you cite** — every claim in the note must be traceable to the code.

### 4. Fallback when Graphify is unavailable

- Explore directly: catalog the layout (`ls`/Glob), then read, in order of trust: `AGENTS.md`, `docs/`, `README.md`, the `Makefile`, then the `*.zsh` scripts and other files the bug touches.
- Follow existing conventions and patterns; note where the code deviates from them.

### 5. Write the issue note

Write to `_woj/00-issues/NNN-<slug>.md` where:

- When a ticket exists, `NNN` and `<slug>` **mirror the ticket's basename** (e.g. ticket `_woj/00-tickets/002-herdr-fails-to-install.md` produces `_woj/00-issues/002-herdr-fails-to-install.md`), making the pair traceable.
- When there is no ticket, scan `_woj/00-issues/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (start at `001` if empty). Use a kebab-case slug of the bug's subject.

Create `_woj/00-issues/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

### 6. Note template

    # <Short imperative title>

    ## Source

    > <the bug report, verbatim>

    ## Ticket

    `_woj/00-tickets/NNN-<slug>.md`

    ## Reproduction

    1. <concrete step>
    2. <concrete step>

    Observed: <what actually happened>

    Expected: <what should have happened>

    ## Root cause

    - <claim, with `file:line`>

    ## Impact

    - <who/what is affected and how badly>

    ## Proposed fix

    - <fix behavior, with the file(s) and approach>

    ## Assumptions

    - <assumption you had to make>

    ## Open questions

    - <unresolved item>

A note is Markdown. **Drop sections that add no value** (`Ticket`, `Open questions`) rather than leaving them empty.

Section guidance:

- **Source** — the bug report verbatim. When no ticket exists, this is the user's raw report and the missing ticket is flagged here (or in the report back).
- **Ticket** — a link to the source ticket when one exists; omit the section otherwise.
- **Reproduction** — ordered steps actually used to confirm the failure, plus observed vs expected behavior. If a step could not be run (unsafe/not reproducible), say so.
- **Root cause** — the trace from symptom to cause, each claim backed by `file:line`.
- **Impact** — blast radius: which scripts, Makefile targets, or user flows break, and under what conditions.
- **Proposed fix** — the behavior the fix should implement and where it belongs in the codebase. Keep it a proposal, not an implementation; the fix behavior is specified next via `/gherkin-note`.
- **Assumptions** — every inference you had to make to complete the investigation.
- **Open questions** — anything the investigation could not settle.

### 7. Verify before finishing

- Re-read the written file and confirm the filename mirrors the source ticket (`NNN-<slug>.md`), or followed the sequence rule when no ticket exists.
- Confirm every root-cause claim carries a `file:line` reference.
- Confirm assumptions and open questions from steps 1–3 actually made it into the note.

## Workflow (update mode)

When a file path to an existing issue note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/00-issues/`.
- Confirm the file exists and is an issue note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not an issue note (no `# ` title with the expected sections), report the mismatch and ask the user to confirm before editing.

### 2. Extract the follow-up conclusions

- Take the remaining arguments as the follow-up conclusions (if any were supplied). Preserve them verbatim as list items, one per conclusion.
- If no conclusions were supplied but the user referenced a prior investigation or discussion, derive them from that context; otherwise note in the Conclusions section that no conclusions were recorded yet.

### 3. Append the Conclusions section

- Read the existing note and append a `## Conclusions` section at the end.
- If the note already has a `## Conclusions` section, do not overwrite it — append the new conclusions to it, preserving the earlier ones.
- Format:

    ## Conclusions

    - <conclusion>
    - <conclusion>

- Leave all existing sections unchanged.
- If a conclusion resolves an item previously listed under `## Open questions`, append the conclusion and optionally strike through the resolved question (e.g. `- ~~<resolved item>~~`), leaving the question text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a list under `## Conclusions`.

## Reporting back

- **Create mode:** tell the user the file created (full path), the reproduction outcome (bug confirmed or not, with observed vs expected), the root cause in one or two lines with `file:line` references, and the proposed fix in one line. Surface any assumptions or open questions so the user can correct the note if needed, and flag a missing ticket if there was none. End with the next step: the fix behavior is specified via `/gherkin-note` with the same `NNN-<slug>`.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any open questions were resolved and struck through, mention them.
