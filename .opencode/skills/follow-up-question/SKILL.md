---
name: follow-up-question
description: Use when a user invokes /follow-up-question, or asks to "run follow-up questions", "grill me on the feature", "clarify open decisions", "ask the open questions", or similar. Reads the feature's Gherkin note (_woj/01-gherkin-note/) and its mirrored architecture note (_woj/02-architecture/), then interviews the user one question at a time in the fixed format from FORMAT.md, recording every question and chosen answer to _woj/03-follow-up-questions/NNN-<slug>.md. Also use when a path to an existing 03 note is passed (update mode): recompute the question frontier and continue the interview, appending to the note.
---

# Follow-up Question

Run a clarifying interview for a feature that has already been specified in a Gherkin note and researched in a codebase-research note. Surface every open decision, unresolved question, and assumption that still needs the user, and ask **one question at a time**, always in the same fixed format, always with a recommended answer. Record the session to a follow-up note under `_woj/03-follow-up-questions/`.

## When to use

- The user invokes `/follow-up-question`.
- The user asks to "run follow-up questions", "grill me", "clarify the feature decisions", or similar.
- The user passes a path to an existing `_woj/03-follow-up-questions/NNN-<slug>.md` note (e.g. `/follow-up-question _woj/03-follow-up-questions/002-setup-logging.md`), or asks to "resume/update the follow-up note". This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/03-follow-up-questions/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it points to a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default). The feature to interview is the named feature slug, or — with no argument — the latest feature (highest `NNN-` prefix) in `_woj/01-gherkin-note/`.

## Question format (always identical)

The fixed question format lives in `FORMAT.md` in this skill folder. The `follow-up-format` plugin force-injects `FORMAT.md` into system context so the shape can never drift. Every question, without exception, uses that shape — yes/no questions included. If the injected format is not in context, read `FORMAT.md` before asking the first question.

## Workflow (create mode)

### 1. Resolve and read the source notes

- Locate the Gherkin note: the named one, or the highest `NNN-` prefix in `_woj/01-gherkin-note/`.
- Locate the mirrored codebase-research note: `_woj/02-architecture/<same NNN>-<same slug>.md`. If it is missing, proceed with the Gherkin note alone and flag the gap to the user.
- Read both in full:
  - Gherkin: `## Source`, `## Assumptions`, `## Open questions`, `## Feature`, `## Background`, `## Scenarios`, and any `## Conclusions` appended by earlier follow-up rounds.
  - Architecture: `## Overview`, `## Software patterns`, `## Gotchas`, `## Types`, `## Readability`, `## Assumptions`, `## Open questions`, `## Conclusions`.

### 2. Build the question frontier

- Derive the set of open decisions. Candidates:
  - Every item under `## Open questions` or `## Assumptions` in either source note.
  - Any behavior, actor, or edge case implied by the scenarios that is ambiguous or underspecified.
  - Risks surfaced under `## Gotchas` that require a product decision (not a fact).
  - Scope questions the Gherkin note left deliberately open.
- Order by dependency: a question whose answer changes how a later question should even be worded goes first; the dependent one waits.
- **Facts are your job, never the user's.** If a frontier item is answerable by inspecting the codebase, docs, or notes, resolve it yourself and do not ask.

### 3. Ask one question at a time

- Ask exactly one question per turn, formatted per the fixed format.
- Wait for the user's answer before asking the next question. Never batch multiple questions into one turn; never bundle a new question into the same message as a progress report.
- Adjust the `<area>` tag and the options to fit the feature. Do not reuse catalog questions verbatim when the feature does not warrant them.

### 4. Handle the answer

- **Answer given:** append the question and the chosen answer to the follow-up note (see Recording note template). Then recompute the frontier and ask the next question.
- **Skip:** do nothing. The question is not recorded; it remains open if downstream questions depend on it, otherwise it is dropped.
- **Ambiguous answer:** reflect it back as the next question in the fixed format, offering the interpretation you are leaning toward as the recommended option.

### 5. Finish

- The session ends when the frontier is empty: every branch asked, nothing silently assumed.
- Confirm with the user (one line) that the recorded answers reflect shared understanding before ending.
- Report back: path of the note written, number of questions answered, and a one-line summary of the key decisions.

## Workflow (update mode)

When the first argument names an existing `_woj/03-follow-up-questions/NNN-<slug>.md` note:

1. Resolve and validate the path (absolute, repo-relative, or `_woj/03-follow-up-questions/`-relative). If it does not exist, report an error and stop — never create a note from an update invocation.
2. Read the existing note: its `## Inputs`, the `## Q&A` answered so far, and the source notes it links to.
3. Recompute the frontier from the already-answered questions plus any newly resolved items.
4. Continue the interview exactly as in create mode, one question at a time.
5. Append new `### Q<n>(<area>)` blocks under `## Q&A`, continuing the session's question numbering from where it stopped. Leave existing entries unchanged.

## Recording note template

Create mode writes to `_woj/03-follow-up-questions/NNN-<slug>.md`, where `NNN` and `<slug>` mirror the source Gherkin note's basename (e.g. Gherkin note `_woj/01-gherkin-note/002-setup-logging.md` produces `_woj/03-follow-up-questions/002-setup-logging.md`), so the whole chain is traceable: feature -> architecture -> clarifications.

Create `_woj/03-follow-up-questions/` if it does not exist. Never overwrite an existing file.

    # <Short feature title> — Follow-up Questions

    ## Source

    > <the original feature request, verbatim>

    ## Inputs

    - Gherkin note: `_woj/01-gherkin-note/NNN-<slug>.md`
    - Architecture note: `_woj/02-architecture/NNN-<slug>.md` (if present)

    ## Q&A

    ### Q1(<area>)

    <question text>

    > <chosen answer>

    ### Q2(<area>)

    <question text>

    > <chosen answer>

Drop nothing that exists; only add entries as the session progresses. Skipped questions produce no entry.

## Question catalog by area

Adapt these to the feature; do not ask ones the notes already answer. Order within a session follows dependency, not catalog order.

| Area | What it clarifies | Example probe |
| --- | --- | --- |
| `scope` | What exactly is in / out of this feature | Which of the implied behaviors are actually part of this feature vs a later one? |
| `actors` | Who performs the behaviors, permissions implied | Who is allowed to run this, and what should non-permitted actors see? |
| `edge-cases` | Boundary conditions the scenarios leave open | How should the tool behave when the target path already exists? |
| `non-goals` | Deliberately excluded work | What should this feature explicitly NOT do, to keep it shippable? |
| `data` | Shapes, persistence, config contracts | What data/config does this feature read and write, and where is it stored? |
| `integration` | Touch points with the rest of the system | Which existing scripts, plugins, or hooks does this plug into? |
| `constraints` | Platform, environment, and hard limits | Which macOS versions and shell environments must be supported? |
| `priority` | Sequencing and effort trade-offs | Is this a must for the first cut, or can it be a follow-up increment? |
| `verification` | Acceptance criterion ambiguity | Is the acceptance criterion an exit code, an observable side effect, or both? |
| `risks` | Gotchas that need a product decision | The architecture note flags a failure mode here — should we fail loudly or recover automatically? |
| `open` | Unresolved items from the source notes | The Gherkin note lists an open question — what is the intended behavior? |

## Reporting back

Tell the user the path of the note written, the number of questions answered, and a one-line summary of the key decisions. In update mode, also note which question numbers were appended.
