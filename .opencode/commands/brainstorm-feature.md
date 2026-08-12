---
description: Generate a structured Gherkin note in _woj/01-gherkin-note/ from a feature request.
---

Write a structured, testable Gherkin note for the feature request below. Do not ask clarifying questions — proceed and record assumptions and open questions in the note. Run this workflow fully even if the `gherkin-note` skill is not loaded.

## Workflow

1. Parse the request: extract actor, goal, benefit, and concrete testable behaviors and edge cases. Discard noise (small talk, tangents, implementation musings) unless it affects observable behavior.

2. Write immediately. If the request is ambiguous, capture it explicitly: list each assumption in an **Assumptions** section and anything unresolved in an **Open questions** section.

3. Filename: write to `_woj/01-gherkin-note/NNN-<feature-name-slug>.md` where:
   - `NNN` is the next sequence number: scan `_woj/01-gherkin-note/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (e.g. `001`, `042`). Start at `001` if the directory is empty or missing.
   - `<feature-name-slug>` is a short kebab-case summary of the feature's name from the request (lowercase, hyphens, no spaces or special characters), e.g. `install-herdr-script`.
   - Create `_woj/01-gherkin-note/` if it does not exist. Never overwrite an existing file.

4. Use this note template (Markdown; Gherkin blocks fenced with triple backticks):

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

5. Gherkin rules:
   - Use keywords `Feature`, `Background`, `Scenario`, `Scenario Outline`, `Examples`, and steps `Given / When / Then / And / But`.
   - Steps must be indented under their block; scenario keywords at the same indentation as `Feature`.
   - Every `Scenario` and `Scenario Outline` must contain at least one `Then` (or an `Examples` table driving one).
   - Use `<angle-bracket>` placeholders in a `Scenario Outline` and bind them in the `Examples` table.
   - Quote string values consistently in `Examples` tables; keep table columns aligned.
   - Prefer `And`/`But` to repeat `Given`/`When`/`Then`.
   - Describe observable behavior, not implementation details.

6. Verify before finishing: re-read the written file and confirm the filename followed the `NNN-<feature-name-slug>.md` rule, the Gherkin blocks are syntactically consistent (keywords, indentation, `Examples` placeholders bound), and the assumptions and open questions from step 2 made it into the note.

## Reporting back

Tell the user the file created (full path) and summarize the scenarios written. If you recorded assumptions or open questions, surface them in one or two lines so the user can correct the note if needed.

Source request:

$ARGUMENTS
