---
name: to-spec
description: Use when a user invokes /to-spec, says "turn this into a spec", "write the implementation spec", "to spec", or asks to merge the feature notes into an implementation spec. Merges the chain of prior notes (Gherkin note _woj/01-gherkin-note/, architecture note _woj/02-architecture/, follow-up Q&A _woj/03-follow-up-questions/, answered questionnaire _woj/04-format-question/) into ONE implementation spec at _woj/05-spec/NNN-<slug>.md with traceable requirements, edge cases, design decisions, and a verification checklist. Also use when a path to an existing 05 spec note is passed (update mode): append a Conclusions section to that note.
---

# To Spec

Merge the accumulated chain of feature notes into ONE implementation spec — a single document that `/tdd` and `/implement` read instead of chasing four notes. Every requirement in the spec traces back to a Gherkin scenario or an answered decision, so nothing is invented during implementation.

## When to use

- The user invokes `/to-spec`.
- The user asks to "turn this into a spec", "write the implementation spec", "merge the notes into a spec", "to spec", or similar phrasing.
- The user passes a path to an existing `_woj/05-spec/NNN-<slug>.md` note (e.g. `/to-spec _woj/05-spec/002-setup-logging.md <conclusions>`), or asks to "update the spec with conclusions", "append conclusions". This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/05-spec/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Locate the chain

- Use the basename the user named (a feature slug or path), or — with no argument — the highest `NNN-` prefix present in `_woj/01-gherkin-note/` (the latest feature).
- Mirror that `NNN-<slug>` basename across the chain: `_woj/02-architecture/`, `_woj/03-follow-up-questions/`, and `_woj/04-format-question/`.
- If a chain member is missing, proceed without it and flag the gap to the user.

### 2. Read every present note in full

- **Gherkin note** (`01-gherkin-note`): `## Source`, `## Assumptions`, `## Open questions`, `## Feature`, `## Background`, `## Scenarios`, and any `## Conclusions` appended by earlier rounds.
- **Architecture note** (`02-architecture`): `## Overview`, `## Software patterns`, `## Gotchas`, `## Types`, `## Readability`, `## Assumptions`, `## Open questions`, `## Conclusions`.
- **Follow-up note** (`03-follow-up-questions`): `## Inputs` and `## Q&A` — the `### Q<n>(<area>)` blocks with their chosen `> Answer:` lines.
- **Questionnaire** (`04-format-question`): `## Questions` — the `### Q<n>(<area>)` blocks with their filled `> Answer:` lines.

Extract what each note contributes: scenarios and acceptance criteria (01), patterns and gotchas (02), decisions and their rationale (03, 04).

### 3. Choose the filename

Write to `_woj/05-spec/NNN-<feature-name-slug>.md`, where `NNN` and `<feature-name-slug>` **mirror the source chain's basename** (e.g. Gherkin note `_woj/01-gherkin-note/002-setup-logging.md` produces `_woj/05-spec/002-setup-logging.md`), so the whole chain stays traceable.

Create `_woj/05-spec/` if it does not exist. Never overwrite an existing file — the mirrored basename guarantees uniqueness.

### 4. Use the spec template

A note is Markdown. Use the template below; **drop sections that add no value** rather than leaving them empty. All fenced blocks use triple backticks.

    # <Short imperative title>

    ## Source

    > <the original request, verbatim>

    ## Inputs

    - Gherkin note: `_woj/01-gherkin-note/NNN-<slug>.md`
    - Architecture note: `_woj/02-architecture/NNN-<slug>.md` (if present)
    - Follow-up questions: `_woj/03-follow-up-questions/NNN-<slug>.md` (if present)
    - Answered questionnaire: `_woj/04-format-question/NNN-<slug>.md` (if present)

    ## Overview

    <one paragraph: what gets built, in what shape, and how it plugs into the repo>

    ## Requirements

    1. <requirement> (from Scenario: <name>)
    2. <requirement> (from Q<n>(<area>) answer)
    3. <requirement> (from Conclusions)

    ## Edge cases

    - <edge case and the expected behavior>

    ## Design decisions

    - <decision> — <rationale> (from Q<n>(<area>) / software pattern)

    ## Out of scope

    - <deliberately excluded work>

    ## Verification checklist

    - [ ] <observable check>

Section guidance:

- **Requirements** — numbered; each one is derived from and traceable to a Gherkin scenario, an answered decision (Q&A or questionnaire answer), or a Conclusions item. Write the trace source in parentheses on the requirement line. Number sequentially.
- **Edge cases** — from the Gherkin edge-case steps, architecture `## Gotchas`, and Q&A answers in the `edge-cases` area.
- **Design decisions** — decisions with rationale, drawn from follow-up answers, questionnaire answers, and architecture `## Software patterns`. State the decision and why, not just the pattern.
- **Out of scope** — from Q&A `non-goals` answers, questionnaire answers, and scenario content deliberately not carried into Requirements.
- **Verification checklist** — observable checks only (Then-steps, acceptance criteria, exit codes, side effects); one checkbox per check. `/tdd` and `/implement` mark them done later.

### 5. Resolve or carry forward open questions

Every open question from the source notes (`## Open questions` and `## Assumptions` in 01/02) must end up either:

- **Answered** — recorded under `## Design decisions` with the deciding answer and its source, or
- **Carried forward** — if still unresolved, listed under `## Design decisions` marked as unresolved, and surfaced to the user in "Reporting back" so they can decide before `/tdd`.

Never silently drop an open question from the chain.

## Workflow (update mode)

When the first argument names an existing `_woj/05-spec/NNN-<slug>.md` note:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/05-spec/`.
- Confirm the file exists and is a spec note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not a spec note (no `# ` title with `## Requirements`), report the mismatch and ask the user to confirm before editing.

### 2. Extract the follow-up conclusions

- Take the remaining arguments as the follow-up conclusions (if any were supplied). Preserve them verbatim as list items, one per conclusion.
- If no conclusions were supplied but the user referenced a prior discussion, derive them from that context; otherwise note in the Conclusions section that no conclusions were recorded yet.

### 3. Append the Conclusions section

- Read the existing note and append a `## Conclusions` section at the end.
- If the note already has a `## Conclusions` section, do not overwrite it — append the new conclusions to it, preserving the earlier ones.
- Format:

    ## Conclusions

    - <conclusion>
    - <conclusion>

- Leave all existing sections unchanged.
- If a conclusion resolves an item previously listed as unresolved under `## Design decisions`, append the conclusion and optionally strike through the resolved item (e.g. `- ~~<resolved item>~~`), leaving the item text in place.

## Verify before finishing

- **Create mode:** re-read the written file. Confirm the filename mirrors the source chain's basename (`NNN-<slug>.md`). Confirm every requirement carries a trace to a source note, every open question was either answered or carried forward, and the template's drop-sections rule was honored. Confirm the frontmatter `name: to-spec` is present and the YAML is valid.
- **Update mode:** re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items, stored as a list.

## Reporting back

- **Create mode:** tell the user the file created (full path), the count of requirements, and a one-line overview of the spec. Mention the next step: `/tdd`. If chain members were missing or open questions were carried forward, surface them in one or two lines so the user can fill the gaps.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any unresolved design decisions were resolved and struck through, mention them.
