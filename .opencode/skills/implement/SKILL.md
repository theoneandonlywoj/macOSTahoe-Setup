---
name: implement
description: Use when a user invokes /implement, or asks to "implement the feature", "implement the spec", "start implementing", or similar. Implements a feature per its spec note from _woj/05-spec/ and its TDD note from _woj/06-tdd/, driving the already-written failing tests to green, and writes a structured implementation note to _woj/07-implement/NNN-<feature-name-slug>.md recording changes, tests run, deviations from spec, and open issues. Also use when a file path to an existing implementation note is passed (or the user wants to update a note with follow-up conclusions): append a Conclusions section to that note.
---

# Implement

Implement a feature per its spec and TDD notes, drive the already-written failing tests to green, and write a structured implementation note under `_woj/07-implement/` that records exactly what changed and why.

## When to use

- The user invokes `/implement`.
- The user asks to "implement the feature", "implement the spec", "start implementing", or similar phrasing.
- The user passes a file path to an existing implementation note (e.g. `/implement _woj/07-implement/002-...md <conclusions>`), or asks to "update the implementation note with conclusions", "append conclusions". This is **update mode** — see "Workflow (update mode)".

Always review `AGENTS.md` and the repo conventions before writing any code, regardless of mode.

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/07-implement/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Read the spec and TDD notes in full

- Locate the source notes in `_woj/05-spec/` and `_woj/06-tdd/`. If the user named one, use the matching basename in both directories. Otherwise use the note with the highest `NNN-` prefix (the latest feature) in each directory.
- Read both notes in full before writing any code:
  - `_woj/05-spec/NNN-<slug>.md` — `Requirements`, `Edge cases`, `Design decisions`, `Verification checklist` define what must be true when you finish.
  - `_woj/06-tdd/NNN-<slug>.md` — `Test plan` and the Red-phase failing tests define what must pass. The failing tests are already written; do not delete or weaken them.
- The implementation note you write must mirror the source basename (see step 5).

### 2. Review repo conventions first

- Read `AGENTS.md` and `README.md` at the repo root; they define project conventions and rules the implementation must respect.
- Read the files the feature touches (e.g. the `*.zsh` script pattern, the `Makefile` targets) and follow existing patterns — do not invent structure.
- Confirm how tests are run in this repo (Makefile target, test runner, script) so step 3 uses the exact commands.

### 3. Implement minimal changes and iterate to green

- Implement the minimal changes that satisfy every spec requirement and make the TDD tests pass. Prefer small, targeted edits over restructuring.
- Run the tests after implementing; iterate on failures until they are green. Record the exact commands and results (see step 5).
- If a requirement cannot be met, or meeting it requires a change to the spec or to the already-written tests, **do not silently change behavior** — record a deviation in the implementation note (step 5) and surface it to the user in the reporting back step.

### 4. Write the implementation note

Write to `_woj/07-implement/NNN-<feature-name-slug>.md` where:

- `NNN` and `<feature-name-slug>` **mirror the source spec note's basename** (e.g. spec note `_woj/05-spec/002-setup-logging.md` produces `_woj/07-implement/002-setup-logging.md`), making the chain traceable.
- When there is no source spec note, scan `_woj/07-implement/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (start at `001` if empty). Use a kebab-case slug of the feature.

Create `_woj/07-implement/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

Use the template below. A note is Markdown; all fenced blocks use triple backticks. **Drop sections that add no value** (`Deviations from spec`, `Open issues`) rather than leaving them empty.

### 5. Note template

    # <Short imperative title>

    ## Source

    Spec note: `_woj/05-spec/NNN-<feature-name-slug>.md`
    TDD note: `_woj/06-tdd/NNN-<feature-name-slug>.md`

    ## Changes

    - <change, with `file:line` reference and a one-line why>

    ## Tests run

    - <exact command>: <result>

    ## Deviations from spec

    - <spec requirement that could not be met as written, why, and what was done instead>

    ## Open issues

    - <unresolved item>

Section guidance:

- **Changes** — every edit made, one bullet per logical change, each with a `file:line` reference and a one-line reason (e.g. "add `install_brew_packages` to `brew.zsh:12` — centralizes installs so tests can stub them"). Reference what the line is at the time of writing.
- **Tests run** — exact commands and their results, e.g. `make test`: all 14 tests pass (11 passed, 3 skipped). If a test had to be skipped or a runner flag changed, say why.
- **Deviations from spec** — any requirement not met exactly as written (spec changed, requirement impossible, behavior intentionally adjusted). Drop the section entirely if nothing deviates.
- **Open issues** — anything unresolved: flaky tests, follow-up work, questions for the user.

### 6. Verify before finishing

- Re-read the written file and confirm the filename mirrors the source spec note (`NNN-<slug>.md`).
- Confirm tests were actually run (exact commands present) and are green.
- Confirm every spec requirement is addressed in `## Changes` or explicitly listed under `## Deviations from spec`.
- Confirm the note has no empty placeholder sections.

## Workflow (update mode)

When a file path to an existing implementation note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/07-implement/`.
- Confirm the file exists and is an implementation note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not an implementation note (no `# ` title with the expected sections), report the mismatch and ask the user to confirm before editing.

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
- If a conclusion resolves an item previously listed under `## Open issues`, append the conclusion and optionally strike through the resolved item (e.g. `- ~~<resolved item>~~`), leaving the item text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a list under `## Conclusions`.

## Reporting back

- **Create mode:** tell the user the file created (full path), summarize the changes made in a few lines, and report the test results (exact commands + outcome). Surface any deviations from spec or open issues in one or two lines. Next step: `/code-quality`.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any open issues were resolved and struck through, mention them.
