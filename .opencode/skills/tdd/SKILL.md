---
name: tdd
description: Use when a user invokes /tdd, says "tdd", "write the tests first", "test-driven development", "write failing tests", or similar. Derives a test plan from the spec note in _woj/05-spec/ and implements the failing tests FIRST (Red phase) before any implementation code, recording the plan and real run output to _woj/06-tdd/NNN-<feature-name-slug>.md. Also use when a file path to an existing TDD note is passed (or the user wants to update a note with follow-up conclusions): append a Conclusions section to that note.
---

# TDD

Derive a test plan from the spec note under `_woj/05-spec/` and write the failing tests FIRST — the Red phase of test-driven development — before any implementation code. Record the plan and the confirmed failure output in a handoff note under `_woj/06-tdd/` so `/implement` can make them pass.

## When to use

- The user invokes `/tdd`.
- The user says "tdd", "write the tests first", "test-driven development", "write failing tests", "red-green", "make a test plan", or similar phrasing.
- The user passes a file path to an existing TDD note (e.g. `/tdd _woj/06-tdd/002-...md <conclusions>`), or asks to "update the TDD note with conclusions", "append conclusions". This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/06-tdd/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Locate and read the spec note

- If the user named a spec note, use that path. Otherwise scan `_woj/05-spec/*.md` and use the note with the highest `NNN-` prefix (the latest spec).
- Read the spec in full: every `Requirements` item, `Edge cases` entry, and `Verification checklist` line. Also read any appended `Conclusions` — they may refine or supersede requirements.
- If no spec note can be located, report the error and stop; do not fabricate a spec. A test plan must be grounded in a real spec note.

### 2. Identify the repo's test conventions

- Read `README.md`, `Makefile`, and `AGENTS.md` for test commands and conventions.
- Search for existing tests: glob `**/test/**`, `*_test.*`, `spec/**`, `test/**`, and look for the test runner referenced by the `Makefile`.
- If a test framework exists, note the framework name, the exact runner command, and where test files live (e.g. `test/`, `tests/`, next to sources).
- If **no** test framework exists in the repo, record that fact in the note's `Test framework notes`, write the test plan anyway, and flag the gap in `Open questions` — do not invent or install a framework.

### 3. Write the TDD note

Write to `_woj/06-tdd/NNN-<slug>.md` where `NNN` and `<slug>` **mirror the source spec note's basename** (e.g. spec note `_woj/05-spec/002-setup-logging.md` produces `_woj/06-tdd/002-setup-logging.md`), making the pair traceable.

Create `_woj/06-tdd/` if it does not exist. Never overwrite an existing file.

Use the template below. A note is Markdown; all fenced blocks use triple backticks. **Drop sections that add no value** (`Assumptions`, `Open questions`) rather than leaving them empty.

### 4. Note template

    # <Short imperative title>

    ## Source

    Spec note: `_woj/05-spec/NNN-<feature-name-slug>.md`

    ## Test framework notes

    <framework name, exact runner command, where test files live, naming conventions — or the fact that no framework exists and this is a gap>

    ## Test plan

    One entry per requirement, edge case, and checklist item from the spec:

    - **Covers:** <requirement or edge case from the spec, quoted>
    - **Test file:** <path where the test goes, following repo conventions>
    - **Test name:** <test name>
    - **Key assertion:** <the assertion that must hold>
    - **Why it should fail now:** <e.g. the implementation does not exist yet>

    ## Red phase

    - **Tests written:** <file paths>
    - **Command run:** <verbatim command>

    ```text
    <failure output, recorded verbatim>
    ```

    ## Assumptions

    - <assumption you had to make>

    ## Open questions

    - <unresolved item, e.g. the missing-framework gap>

### 5. Write and run the failing tests (Red phase)

- Write the tests from the plan, following the repo's existing conventions (framework, file location, naming).
- The tests must be runnable and must fail now, because the behavior they assert does not exist yet. A test that passes at this stage is a red flag — re-check the assertion.
- Run the exact runner command and record the real output verbatim in the `Red phase` section. Do not paraphrase or pre-guess failures.
- If no test framework exists (per step 2), write no test files: record in `Red phase` that no runnable command exists yet and leave the run blocked, with the gap flagged in `Open questions`.

### 6. Verify before finishing

- Re-read the written note and confirm the filename mirrors the source spec note (`NNN-<slug>.md`).
- Confirm every requirement, edge case, and checklist item has an entry in `Test plan`.
- Confirm the `Red phase` section records real run output (or the documented missing-framework gap), not fabricated results.

## Workflow (update mode)

When a file path to an existing TDD note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/06-tdd/`.
- Confirm the file exists and is a TDD note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not a TDD note (no `# ` title with a `Test plan` / `Red phase`), report the mismatch and ask the user to confirm before editing.

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

- Leave the existing `Source`, `Test framework notes`, `Test plan`, `Red phase`, `Assumptions`, and `Open questions` content unchanged.
- If a conclusion resolves an item previously listed under `## Open questions`, append the conclusion and optionally strike through the resolved question (e.g. `- ~~<resolved item>~~`), leaving the question text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a list under `## Conclusions`.

## Reporting back

- **Create mode:** tell the user the file created (full path), the test framework found (or the gap if none exists), and the number of failing tests confirmed in the Red phase. Surface assumptions and open questions in one or two lines, then state the next step: `/implement`.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any open questions were resolved and struck through, mention them.
