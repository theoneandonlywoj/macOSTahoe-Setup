---
name: format-question
description: Use when a user invokes /format-question, or asks to "format the questions", "make me a questionnaire", "share the questions", or similar. Turns the recorded follow-up Q&A session (_woj/03-follow-up-questions/NNN-<slug>.md) into a standalone, shareable questionnaire at _woj/04-format-question/NNN-<slug>.md that the user can answer outside the session, presents it, and then WAITS for the answers — nothing proceeds past this waiting point. Also use when a path to an existing 04 questionnaire is passed (update mode): append the answers to that note, preserving its content.
---

# Format Question

Turn a recorded follow-up Q&A session into a standalone, shareable questionnaire saved under `_woj/04-format-question/` that the user can answer outside the session — then WAIT. This is a waiting point in the workflow: the questionnaire is the bridge between the clarifying interview and the decisions flowing back into the Gherkin note.

## When to use

- The user invokes `/format-question`.
- The user asks to "format the questions", "make me a questionnaire", "share the questions", "write out the questions for me", or similar.
- The user passes a path to an existing `_woj/04-format-question/NNN-<slug>.md` questionnaire (e.g. `/format-question _woj/04-format-question/002-setup-logging.md <answers>`), or asks to "record the answers", "append the answers to the questionnaire". This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/04-format-question/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it points to a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default). The source session is the named `_woj/03-follow-up-questions/` note, or — with no argument — the note with the highest `NNN-` prefix in that directory.

## Workflow (create mode)

### 1. Locate and read the source note

- Locate the follow-up note: the named `_woj/03-follow-up-questions/<path>.md`, or the note with the highest `NNN-` prefix in `_woj/03-follow-up-questions/`. If the directory is empty or missing, report an error and stop — there is no session to format.
- Read it in full: `## Source`, `## Inputs`, and every `### Q<n>(<area>)` block (question text plus the recorded `> <chosen answer>`).

### 2. Write the questionnaire

Write to `_woj/04-format-question/NNN-<slug>.md` where `NNN` and `<slug>` **mirror the source follow-up note's basename** (e.g. follow-up note `_woj/03-follow-up-questions/002-setup-logging.md` produces `_woj/04-format-question/002-setup-logging.md`), so the chain stays traceable: feature -> architecture -> clarifications -> questionnaire.

Create `_woj/04-format-question/` if it does not exist. Never overwrite an existing file.

### 3. Note template

A questionnaire is Markdown. Use the template below; all fenced blocks use triple backticks.

```markdown
# <Short feature title> — Questionnaire

## Source

> <the original feature request, verbatim>

Follow-up note: `_woj/03-follow-up-questions/NNN-<slug>.md`

## Questions

### Q1(<area>)

<question text>

Options:
- <option>
- <option>

Recommended: <recommended answer>

> Answer:
```

For each `### Q<n>(<area>)` block in the source session, write exactly one block under `## Questions` using the **same numbering** as the session. Each block carries: the question text, the options offered in the original session, the recommended answer, and a blank `> Answer:` line. The original request quote goes under `## Source` only if present in the follow-up note; the link to the 03 note always goes there.

### 4. Present and wait

- Present the questionnaire to the user and explicitly WAIT for their answers. Do not proceed beyond this point — this step is a waiting point in the workflow and the skill ends here.
- Do not re-interview the user, do not re-ask the questions in chat, do not guess answers.

### 5. Record the answers

When the user answers (in this or a later session, via update mode):

- Fill each `> Answer:` line in the questionnaire with the chosen answer, preserving everything else.

### 6. Hand off the decisions

- Instruct the user to run `/gherkin-note _woj/01-gherkin-note/NNN-<slug>.md <conclusions>` with the answers as conclusions, so the decisions flow back into the Gherkin note (gherkin-note's update mode).

## Workflow (update mode)

When the first argument names an existing `_woj/04-format-question/NNN-<slug>.md` questionnaire:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/04-format-question/`.
- Confirm the file exists and is a questionnaire. If it does not exist, report an error and stop — never create a questionnaire from an update invocation.
- If the file exists but is not a questionnaire (no `# <title> — Questionnaire` title with `## Questions` blocks), report the mismatch and ask the user to confirm before editing.

### 2. Record the answers

- Take the remaining arguments as answers. Fill each blank `> Answer:` line under the matching `### Q<n>(<area>)` block, preserving all existing content.
- If answers cannot be mapped to the blank lines (or none were supplied), append an `## Answers` section at the end listing them, preserving the rest of the note.
- Leave the `## Source` and `## Questions` sections unchanged.

## Verify before finishing

- Re-read the written file and confirm the filename mirrors the source note's basename (`NNN-<slug>.md`).
- Confirm every `### Q<n>(<area>)` from the source session appears with its formatted block: question text, options, recommended answer, and blank `> Answer:` line.
- In update mode, confirm every question carries an answer (filled inline or listed under `## Answers`) and the original content is unchanged.

## Reporting back

- **Create mode:** tell the user the file created (full path), the number of questions formatted, and prompt them to answer the questions (in chat, or by passing the answers back via update mode).
- **Update mode:** tell the user which file was updated (full path) and summarize the answers recorded, then point them at the handoff — run `/gherkin-note _woj/01-gherkin-note/NNN-<slug>.md <conclusions>` with the answers as conclusions.
