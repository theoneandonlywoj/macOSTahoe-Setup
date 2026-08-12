---
name: workflow-visualization
description: Use when a user invokes /workflow-visualization, or asks to "update the workflow diagram", "visualize the workflow", "the workflow changed", or similar. Reads the workflow diagram in _workflow.md at the repo root, edits its mermaid block to reflect workflow steps added/removed/renamed, edges changed, or labels changed, verifies the diagram stays valid, and records the change in a handoff note at _woj/13-workflow-visualization/NNN-<slug>.md. Never touches _workflow_backup_do_no_touch.md.
---

# Workflow Visualization

Keep `_workflow.md` at the repo root in sync with the actual workflow. `_workflow.md` contains exactly one mermaid block that maps every step command in the feature workflow to a graph node, with labeled edges showing how steps flow into one another. This skill edits that diagram AND records what changed in a handoff note under `_woj/13-workflow-visualization/`, so the change is traceable and `/guide-me` can pick it up from disk.

## When to use

- The user invokes `/workflow-visualization`.
- The user asks to "update the workflow diagram", "visualize the workflow", "sync the workflow", or notes that "the workflow changed".
- A step was added, removed, renamed, or reordered in conversation, or an edge/label between steps changed, and the diagram in `_workflow.md` must reflect it.

Never touch `_workflow_backup_do_no_touch.md` — its name is the rule.

## Mode selection

At the start, inspect the first argument:

- If it names an existing `_woj/13-workflow-visualization/` note (absolute, repo-root-relative, or dir-relative path to a `NNN-<slug>.md` note), use **update mode**: apply the new diagram change and append a new `## Update <n>` section to that note, preserving earlier content.
- If it names a file that does **not** exist, report an error and stop — never create a note from an update invocation.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Read `_workflow.md` in full

- Read the entire file. Confirm it contains exactly one fenced mermaid block (` ```mermaid ` ... ` ``` `) declaring `flowchart TD`.
- Note every node id and its shape: `T["/create-ticket"]`, `A["/brainstorm-feature"]`, `B["/gherkin-note"]`, `P["/investigate-issue"]`, `D["/follow-up-question"]`, `E["/format-question"]`, `F[Wait for response]`, `C["/codebase-research"]`, `G["/to-spec"]`, `H["/tdd"]`, `I["/implement"]`, `J["/code-quality"]`, `S{User acceptance}`, `L["/code-versioning-organisation"]`, `M["/pr-gh"]`, `Q["/resolve-conflicts"]`, `N["/investigate-feedback"]`, `O["/implement-feedback"]`, `K["/workflow-visualization"]`, `R["/guide-me"]`.
- Note every edge and its label: `T -->|feature| A`, `T -->|bug| P`, `A --> B`, `P --> B`, `B --> D`, `D --> E`, `E --> F`, `F -->|answered| B`, `F -->|break| C`, `C --> G`, `G --> H`, `H --> I`, `I --> J`, `J --> S`, `S -->|rejected| I`, `S -->|approved| L`, `L --> M`, `M --> Q`, `Q --> N`, `N --> O`, `O -->|workflow impact| K`, `O -->|no workflow impact| H`, `K --> R`, `R --> T`.

### 2. Determine the workflow change from the conversation

Decide what changed and how to map it onto the diagram:

- **Step added** — a new node line is needed. Derive the node id from the step's command name (e.g. `/new-step` becomes `N["/new-step"]`), pick an unused letter id, and add the edges that connect it into the flow.
- **Step removed** — delete the node line and every edge line that references it.
- **Step renamed** — rename the node's label text only (e.g. `A["/brainstorm-feature"]` to `A["/brainstorm-ideas"]`); keep the node id unchanged so existing edges stay valid. Rename an id only if the step's command name itself changed its first letter.
- **Edge changed** — add, remove, or re-point the `-->` edge lines.
- **Label changed** — update only the `|label|` portion of the affected edge line (e.g. `S -->|rejected| I` to `S -->|rework| I`).

If the conversation is ambiguous about what changed, make the most conservative edit and note the assumption in the handoff note.

### 3. Edit the mermaid block

Apply the change as a minimal diff inside the single fenced mermaid block in `_workflow.md`:

- Keep node labels in the `["/command"]` shape for command steps, `[Wait ...]` for wait states, and `{Decision}` for decision nodes (e.g. `F[Wait for response]`, `S{User acceptance}`).
- Use `-->` for unlabeled edges and `-->|label|` for labeled edges.
- Use a short, descriptive edge label (lowercase, like `feature`, `bug`, `answered`, `break`, `rejected`, `approved`, `workflow impact`).
- Keep the workflow order in mind: create-ticket -> brainstorm-feature / gherkin-note -> investigate-issue (bugs) -> follow-up-question -> format-question -> codebase-research -> to-spec -> tdd -> implement -> code-quality -> code-versioning-organisation -> pr-gh -> resolve-conflicts -> investigate-feedback -> implement-feedback -> workflow-visualization -> guide-me.
- Leave all non-mermaid content in `_workflow.md` untouched.

### 4. Write the handoff note

Write to `_woj/13-workflow-visualization/NNN-<slug>.md` where:

- `NNN` and `<slug>` **mirror the source note's basename** when the change was triggered by a feature chain (e.g. implementation note `_woj/12-implement-feedback/002-setup-logging.md` produces `_woj/13-workflow-visualization/002-setup-logging.md`), keeping the chain traceable.
- When there is no source feature note (a standalone workflow change), scan `_woj/13-workflow-visualization/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (start at `001` if empty). Use a kebab-case slug describing the change (e.g. `add-resolve-conflicts-step`).

Create `_woj/13-workflow-visualization/` if it does not exist. Never overwrite an existing file — if a note with the same basename already exists, append a new `## Update <n>` section instead, preserving the earlier content.

Note template:

    # <Short change title> — Workflow Update

    ## Source

    <triggering note path, or the request that drove the change>

    ## Change

    - <nodes added/removed/renamed, with ids and labels>
    - <edges added/removed/re-pointed>
    - <labels changed>

    ## Rationale

    <why the workflow changed>

    ## Verified

    - <the mermaid checks that passed, from the section below>

### 5. Mermaid editing rules

- The block must open with ` ```mermaid ` and close with ` ``` ` (triple backticks), with `flowchart TD` on the first line inside.
- One node or edge per line; indent with four spaces for readability, matching the existing style.
- Node ids are single uppercase letters; quotes around command labels; square brackets for steps, curly braces for decisions.
- Edge labels live inside pipes: `-->|label|`.

## Workflow (update mode)

When a path to an existing `_woj/13-workflow-visualization/` note is provided:

1. Resolve and validate the path (absolute, repo-root-relative, or `_woj/13-workflow-visualization/`-relative). If it does not exist, report an error and stop.
2. Re-read `_workflow.md` and determine the new change per steps 1–3 of create mode.
3. Apply the edit to `_workflow.md`.
4. Append a new `## Update <n>` section (continuing the numbering) to the note with the new `## Change`, `## Rationale`, and `## Verified` content. Leave existing content unchanged.

## Verify before finishing

- Re-read `_workflow.md` in full and confirm the diagram is a single valid `flowchart TD` block fenced with triple backticks.
- Confirm every node referenced in an edge line is defined by a node line (no dangling references), and every node defined is reachable or intentionally terminal.
- Confirm quotes and square/curly brackets are balanced on every line.
- Confirm there are no duplicate node ids.
- Confirm edge labels use the `-->|label|` syntax and plain `-->` otherwise.
- Confirm the edit is minimal — only the nodes/edges/labels that actually changed were touched.
- Re-read the handoff note and confirm the filename followed the `NNN-<slug>.md` rule (mirrored basename, or next sequence + change slug), and that `## Change` documents the actual diagram diff.
- Confirm `_workflow_backup_do_no_touch.md` was not read, edited, or created.

## Reporting back

Tell the user: the handoff note path, what changed in the diagram and why — which nodes were added, removed, or renamed, which edges were added, removed, or re-pointed, and which labels changed. If the change was derived from an assumption rather than an explicit statement, say so in one line. End with the next step: `/guide-me` to re-orient the user in the updated workflow.
