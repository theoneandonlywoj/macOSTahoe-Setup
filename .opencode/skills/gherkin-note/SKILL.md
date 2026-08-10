---
name: gherkin-note
description: Use when a user requests a Gherkin feature note, says "gherkin", or invokes /gherkin-note. Analyzes a feature request and writes a structured, testable Gherkin note to _woj/01-gherkin-note/NNN-<feature-name-slug>.md. Write immediately even when the request is ambiguous, recording assumptions and open questions in the note. Also use when a file path to an existing Gherkin note is passed (or the user wants to update a note with follow-up conclusions): append a Conclusions section to that note.
---

# Gherkin Note

Turn a feature request into a structured, testable Gherkin note saved under `_woj/01-gherkin-note/`, or update an existing note with follow-up conclusions.

## When to use

- The user invokes `/gherkin-note`.
- The user asks to "make a gherkin note", "write a feature file", or otherwise wants Gherkin behavior specifications for a request.
- The user passes a file path to an existing note (e.g. `/gherkin-note _woj/01-gherkin-note/002-...md <conclusions>`), or asks to "update the note with conclusions", "append conclusions", "capture follow-ups", or similar. This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/01-gherkin-note/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it points to a note that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Parse the request

Analyze the source request (typically the command's `$ARGUMENTS`). Extract:

- **Actor / role** — who performs the behavior.
- **Goal** — what the actor wants to accomplish.
- **Benefit** — why it matters.
- **Behaviors** — concrete, testable rules and edge cases.

Discard noise (small talk, tangents, implementation musings) unless it affects observable behavior.

### 2. Write immediately — never block on questions

Do not stop to ask clarifying questions. If the request is ambiguous, proceed and capture that ambiguity explicitly:

- List each assumption you had to make in the **Assumptions** section.
- List anything still unresolved in the **Open questions** section.

### 3. Choose the filename

Write to `_woj/01-gherkin-note/NNN-<feature-name-slug>.md` where:

- `NNN` is the next sequence number: scan `_woj/01-gherkin-note/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (e.g. `001`, `042`). If the directory is empty or missing, start at `001`.
- `<feature-name-slug>` is a short kebab-case summary of the feature's name from the request (lowercase, hyphens, no spaces or special characters), e.g. `install-herdr-script`.

Create `_woj/01-gherkin-note/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

### 4. Use the note template

A note is Markdown. The `## Feature`, `## Background`, and `## Scenarios` sections each contain a Gherkin block fenced with triple backticks (` ```gherkin `). Full skeleton:

    # <Short imperative title>

    ## Source

    > <the request, verbatim>

    ## Assumptions

    - <assumption you had to make>

    ## Open questions

    - <unresolved item>

    ## Feature

    ```gherkin
    Feature: <name>
      As a <actor>
      I want <goal>
      So that <benefit>
    ```

    ## Background

    Add a `Background:` block only when multiple scenarios share preconditions.

    ```gherkin
    Background:
      Given <shared setup>
    ```

    ## Scenarios

    ```gherkin
    Scenario: <name>
      Given <precondition>
      When <action>
      Then <observable outcome>

    Scenario Outline: <name>
      Given <precondition with <placeholder>>
      When <action with <placeholder>>
      Then <outcome with <placeholder>>

      Examples:
        | <placeholder> | <another> |
        | <value>       | <value>   |
    ```

Drop sections that add no value (`Open questions`, `Background`) rather than leaving them empty.

### 5. Gherkin rules to follow

- Use keywords `Feature`, `Background`, `Scenario`, `Scenario Outline`, `Examples`, and steps `Given / When / Then / And / But`.
- Steps must be indented under their block; scenario keywords at the same indentation as `Feature`.
- Every `Scenario` and `Scenario Outline` must contain at least one `Then` (or an `Examples` table driving one).
- Use `<angle-bracket>` placeholders in a `Scenario Outline` and bind them in the `Examples` table.
- Quote string values consistently in `Examples` tables; keep table columns aligned.
- Prefer `And`/`But` to repeat `Given`/`When`/`Then`.
- Describe observable behavior, not implementation details.

### 6. Verify before finishing

- Re-read the written file and confirm the filename followed the `NNN-<feature-name-slug>.md` rule.
- Confirm the Gherkin block is syntactically consistent (keywords, indentation, `Examples` placeholders bound).
- Confirm assumptions and open questions from step 2 actually made it into the note.

## Workflow (update mode)

When a file path to an existing note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/01-gherkin-note/`.
- Confirm the file exists and is a Gherkin note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not a Gherkin note (no `# ` title with Gherkin blocks), report the mismatch and ask the user to confirm before editing.

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

- Leave the existing `## Source`, `## Assumptions`, `## Open questions`, `## Feature`, `## Background`, and `## Scenarios` content unchanged.
- If a conclusion resolves an item previously listed under `## Open questions`, append the conclusion and optionally strike through the resolved question (e.g. `- ~~<resolved item>~~`), leaving the question text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a numbered list under `## Conclusions`.

## Reporting back

- **Create mode:** tell the user the file created (full path) and summarize the scenarios written. If you recorded assumptions or open questions, surface them in one or two lines so the user can correct the note if needed.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any open questions were resolved and struck through, mention them.
