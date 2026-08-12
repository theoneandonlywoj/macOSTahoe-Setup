---
name: create-ticket
description: Use when a user invokes /create-ticket, or asks to "create a ticket", "file a ticket", "write a ticket for this", "log this as a ticket", or similar. Turns a raw feature request or bug report into a ticket note at _woj/00-tickets/NNN-<slug>.md, capturing the type, description, acceptance criteria, assumptions, and open questions without blocking on clarifying questions. Also use when a path to an existing ticket note is passed (update mode): append a Conclusions section to that note.
---

# Create Ticket

Turn a raw feature request or bug report into a ticket note under `_woj/00-tickets/`, or update an existing ticket note with follow-up conclusions. This is the first step of the feature workflow: it captures the request as-is so later steps (brainstorm/gherkin for features, investigation for bugs) can build on it.

## When to use

- The user invokes `/create-ticket`.
- The user asks to "create a ticket", "file a ticket", "write a ticket for this", "log this as a ticket", or otherwise hands over a raw feature request or bug report.
- The user passes a file path to an existing ticket note (e.g. `/create-ticket _woj/00-tickets/002-...md <conclusions>`), or asks to "update the ticket with conclusions", "append conclusions", "capture follow-ups", or similar. This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/00-tickets/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it points to a note that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Parse the request

Analyze the source request (typically the command's `$ARGUMENTS`). Infer the type and extract the essentials:

- **Type** — `feature` or `bug`, inferred from the wording of the request.
  - Feature request: someone wants new behavior added.
  - Bug report: existing behavior is wrong, missing, or failing.
- **For features** — the **actor** (who benefits), the **goal** (what they want to do), and the **benefit** (why it matters).
- **For bugs** — the **symptoms** (what actually happens), the **impact** (who or what is harmed), and the **expected vs actual behavior** (what should happen vs what does).
- **Acceptance criteria** — concrete, testable, observable outcomes implied by the request (exit codes, visible effects, file changes, command outputs).

Discard noise (small talk, tangents, implementation musings) unless it affects observable behavior.

### 2. Write immediately — never block on questions

Do not stop to ask clarifying questions. If the request is ambiguous, proceed and capture that ambiguity explicitly:

- List each assumption you had to make in the **Assumptions** section.
- List anything still unresolved in the **Open questions** section.

### 3. Choose the filename

Write to `_woj/00-tickets/NNN-<slug>.md` where:

- `NNN` is the next sequence number: scan `_woj/00-tickets/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (e.g. `001`, `042`). If the directory is empty or missing, start at `001`.
- `<slug>` is a short kebab-case summary of the ticket's subject from the request (lowercase, hyphens, no spaces or special characters), e.g. `install-herdr-script`, `fix-backup-crash`.

Create `_woj/00-tickets/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

### 4. Use the note template

A note is Markdown; all fenced blocks use triple backticks. Full skeleton:

    # <Short imperative title>

    ## Source

    > <the request, verbatim>

    ## Type

    feature | bug

    ## Description

    For a feature:
    - **Actor:** <who benefits>
    - **Goal:** <what they want to do>
    - **Benefit:** <why it matters>

    For a bug:
    - **Symptoms:** <what actually happens>
    - **Impact:** <who or what is harmed>
    - **Expected vs actual:** <what should happen vs what does>

    ## Acceptance criteria

    - <testable, observable outcome>
    - <testable, observable outcome>

    ## Assumptions

    - <assumption you had to make>

    ## Open questions

    - <unresolved item>

Drop sections that add no value (`Assumptions`, `Open questions`) rather than leaving them empty.

### 5. Verify before finishing

- Re-read the written file and confirm the filename followed the `NNN-<slug>.md` rule.
- Confirm the `## Type` line says `feature` or `bug` and matches the parsed request.
- Confirm assumptions and open questions from step 2 actually made it into the note.

## Workflow (update mode)

When a file path to an existing ticket note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/00-tickets/`.
- Confirm the file exists and is a ticket note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not a ticket note (no `# ` title with `## Source` and `## Type` sections), report the mismatch and ask the user to confirm before editing.

### 2. Extract the follow-up conclusions

- Take the remaining arguments as the follow-up conclusions (if any were supplied). Preserve them verbatim as list items, one per conclusion.
- If no conclusions were supplied but the user referenced a prior discussion, derive the conclusions from that context; otherwise note in the Conclusions section that no conclusions were recorded yet.

### 3. Append the Conclusions section

- Read the existing note and append a `## Conclusions` section at the end.
- If the note already has a `## Conclusions` section, do not overwrite it — append the new conclusions to it, preserving the earlier ones.
- Format:

    ## Conclusions

    - <conclusion>
    - <conclusion>

- Leave the existing `## Source`, `## Type`, `## Description`, `## Acceptance criteria`, `## Assumptions`, and `## Open questions` content unchanged.
- If a conclusion resolves an item previously listed under `## Open questions`, append the conclusion and optionally strike through the resolved question (e.g. `- ~~<resolved item>~~`), leaving the question text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a list under `## Conclusions`.

## Reporting back

- **Create mode:** tell the user the file created (full path), the ticket type (`feature` or `bug`), and a one-line summary of the ticket. Surface any assumptions or open questions in one or two lines so the user can correct the note if needed. Point to the next step: for a feature ticket, run `/brainstorm-feature` (writes the Gherkin note); for a bug ticket, run `/investigate-issue`.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any open questions were resolved and struck through, mention them.
