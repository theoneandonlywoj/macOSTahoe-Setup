---
name: code-quality
description: Use when a user invokes /code-quality, or asks to "review my code", "check the implementation", "is the implementation good", "code quality review", or similar. Reviews the implementation described in an implement note from _woj/07-implement/ against its spec note and the repo's quality checks, then writes a verdict note (approve or changes-requested) to _woj/08-code-quality/NNN-<slug>.md. Also use when a file path to an existing code-quality note is passed (or the user wants to update a note with follow-up conclusions): append a Conclusions section to that note.
---

# Code Quality

Review the implementation handed off by `/implement` for quality, run the repo's checks, and issue a verdict — `approve` or `changes-requested` — saved as a note under `_woj/08-code-quality/` that mirrors the implement note's basename, or update an existing note with follow-up conclusions.

## When to use

- The user invokes `/code-quality`.
- The user asks to "review my code", "check the implementation", "is the implementation good", "code quality review", or similar phrasing.
- The user passes a file path to an existing code-quality note (e.g. `/code-quality _woj/08-code-quality/002-...md <conclusions>`), or asks to "update the verdict with conclusions", "append conclusions". This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/08-code-quality/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Read the implement note and the spec

- Locate the implement note in `_woj/07-implement/`. If the user named one, use it; otherwise use the note with the highest `NNN-` prefix (the latest handoff).
- Read it in full: `Source`, `Changes` (with `file:line`), `Tests run`, `Deviations`, and `Open issues` tell you what was changed and why.
- Read the spec note in `_woj/05-spec/` with the **same basename** to review the implementation against intent. If it is missing, review against the implement note's `Source` and flag the missing spec.

### 2. Discover and run the repo's quality checks

- Find the checks from `README.md` and the `Makefile`: lint, typecheck, format, and test targets (e.g. `shellcheck` for `*.zsh`, `make lint`, `make check`, `make test`). Note any `AGENTS.md` instructions about checks.
- Run every check that applies to the changed files and record the exact commands and their results (pass/fail, output summary).
- If no checks exist, say so explicitly in the note and review manually.
- If a check fails, treat it as a finding (critical if it blocks the build, otherwise major/minor) — never paper over a failing check.

### 3. Review the changes

Assess the changes against:

- **Spec requirements** — every scenario/requirement in the spec note is addressed; nothing specified is missing.
- **Repo conventions** — the `*.zsh` script pattern, Makefile target style, and any conventions documented in `AGENTS.md`/`README.md` are followed.
- **Readability** — naming, cohesion, comment quality, script size; whether a new person can follow the change.
- **Security** — no secrets committed, no unsafe shell (`eval` on untrusted input, unquoted variables, `rm` without care), no world-writable files.
- **Edge cases** — those called out in the spec are handled; `set -euo pipefail` or equivalent defensive behavior in `*.zsh` scripts is present where expected.

Record every issue as a finding with severity, location, and suggested fix (see the template below).

### 4. Write the code-quality note

Write to `_woj/08-code-quality/NNN-<slug>.md` where:

- `NNN` and `<slug>` **mirror the source implement note's basename** (e.g. implement note `_woj/07-implement/002-setup-logging.md` produces `_woj/08-code-quality/002-setup-logging.md`), making the chain traceable.
- When there is no implement note, scan `_woj/08-code-quality/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (start at `001` if empty). Use a kebab-case slug of the subject.

Create `_woj/08-code-quality/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

Use the template below. A note is Markdown. **Drop sections that add no value** (`Notes`) rather than leaving them empty.

### 5. Note template

    # <Short imperative title>

    ## Source

    Implement note: `_woj/07-implement/NNN-<slug>.md`
    Spec note: `_woj/05-spec/NNN-<slug>.md`

    ## Checks run

    - `<command>` — <result, e.g. "shellcheck passed on all scripts">
    - `<command>` — <result>

    (or: no automated checks exist in this repo; reviewed manually.)

    ## Findings

    - **critical** — `file:line` — <issue> — fix: <suggested fix>
    - **major** — `file:line` — <issue> — fix: <suggested fix>
    - **minor** — `file:line` — <issue> — fix: <suggested fix>
    - **nit** — `file:line` — <issue> — fix: <suggested fix>

    ## Verdict

    `approve` or `changes-requested`

    ## Notes

    <anything else worth recording, e.g. deviations from the spec that were accepted, skipped edge cases>

Severity guidance:

- **critical** — breaks the build, exposes secrets, or corrupts data; must be fixed before anything else.
- **major** — violates the spec or a repo convention, or will fail in a plausible edge case.
- **minor** — should be improved but the change is acceptable as-is.
- **nit** — style-level polish, non-blocking.

### 6. Verify before finishing

- Re-read the written file and confirm the filename mirrors the implement note (`NNN-<slug>.md`).
- Confirm every finding has a severity and a `file:line` reference, and a suggested fix.
- Confirm the verdict matches the findings: any critical or major finding ⇒ `changes-requested`; otherwise `approve`.

## Workflow (update mode)

When a file path to an existing code-quality note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/08-code-quality/`.
- Confirm the file exists and is a code-quality note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not a code-quality note (no `# ` title with the expected sections), report the mismatch and ask the user to confirm before editing.

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
- If a conclusion resolves an item previously listed under `## Notes` or changes the verdict, append the conclusion and optionally strike through the resolved item (e.g. `- ~~<resolved item>~~`), leaving the original text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a list under `## Conclusions`.

## Routing the outcome

After writing the verdict, route the handoff:

- **`changes-requested`** — tell the user the review found issues and that the next step is `/implement` to address them.
- **`approve`** — tell the user the implementation is approved and that the next step is `/code-versioning-organisation`.

## Reporting back

- **Create mode:** tell the user the file created (full path), the checks run with their results, the verdict, and the next step per the routing rules above. Summarize the top findings in one or two lines.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any items were resolved and struck through, mention them.
