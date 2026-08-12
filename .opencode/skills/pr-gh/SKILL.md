---
name: pr-gh
description: Use when the user invokes /pr-gh, or asks to "create the pull request", "open a PR", "make a PR", "submit a PR", "pr-gh", or similar. Creates a GitHub pull request via the gh CLI for the current feature branch, grounded in the versioning note from _woj/09-code-versioning/, and records it to _woj/10-pr/NNN-<slug>.md. Also use when a file path to an existing PR note is passed (or the user wants to update a note with follow-up conclusions): append a Conclusions section to that note.
---

# Pull Request (gh)

Create a GitHub pull request via the `gh` CLI and record it in a PR note under `_woj/10-pr/`, or update an existing PR note with follow-up conclusions.

## When to use

- The user invokes `/pr-gh`.
- The user asks to "create the pull request", "open a PR", "make a PR", "submit this as a PR", or similar phrasing.
- The user passes a file path to an existing PR note (e.g. `/pr-gh _woj/10-pr/002-...md <conclusions>`), or asks to "update the PR note with conclusions", "append conclusions", "record review feedback", or similar. This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/10-pr/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Locate the versioning note

- If the user named a versioning note, use it. Otherwise use the note with the highest `NNN-` prefix in `_woj/09-code-versioning/` (the latest).
- If no versioning note exists, tell the user to run `/code-versioning-organisation` first and stop.
- Read the note in full: `Source`, `Branch`, `Commit plan`, `Checklist`, and any `Conclusions` appended by downstream skills. It tells you which branch to open the PR from and what the commits are supposed to contain.

### 2. Verify git state

- **Current branch:** `git branch --show-current` must match the `Branch` in the versioning note. If it does not, tell the user to switch branches and stop.
- **Commits exist:** `git log --oneline -5` — confirm the planned commits are present and match the `Commit plan`.
- **Uncommitted work:** if `git status` shows changes that are not committed, tell the user to commit them first (`/commit`) and stop — do not open a PR with a dirty working tree.
- **Branch pushed:** check `git status` and compare `git log origin/<branch>..HEAD`. If local commits are ahead of `origin/<branch>`, push first with `git push -u origin <branch>`; a PR cannot be created from an unpushed branch.

### 3. Draft the PR title and body

- **Title:** Conventional Commits style per the commit-conventions skill — imperative, scoped, e.g. `feat(<scope>): <description>`. Derive it from the `Commit plan` (the type, scope, and subject of the commits being submitted).
- **Body:** a summary of the changes (what and why, from the `Commit plan` and `Checklist`) and links to the related `_woj/` notes (ticket, spec, implement — whichever exist) as repo-relative paths, e.g. `_woj/01-gherkin-note/002-setup-logging.md`.

### 4. Create the PR

- Determine the base branch: the repo's default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, or `git remote show origin`).
- Head branch: the current branch.
- Create with:

    ```bash
    gh pr create --title "<title>" --body "<body>"
    ```

- Capture the PR URL that `gh pr create` prints — it is the record of truth for the note.
- If `gh` is unavailable or no remote is configured, record the error, save the drafted title and body in the note, and state that creation was deferred — **never fabricate a PR URL**.

### 5. Write the PR note

Write to `_woj/10-pr/NNN-<slug>.md` where:

- `NNN` and `<slug>` **mirror the versioning note's basename** (e.g. versioning note `_woj/09-code-versioning/002-setup-logging.md` produces `_woj/10-pr/002-setup-logging.md`), keeping the chain traceable.

Create `_woj/10-pr/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

Use the template below. A note is Markdown; all fenced blocks use triple backticks. **Drop sections that add no value** (`Notes`) rather than leaving them empty.

    # <Short imperative title>

    ## Source

    Versioning note: `_woj/09-code-versioning/NNN-<slug>.md`

    ## PR

    <URL of the pull request, with its number, e.g. `https://github.com/<owner>/<repo>/pull/42` — or, if creation was deferred: "Creation deferred: <reason>" and no URL>

    ## Body

    ```markdown
    <the title and body exactly as submitted to gh pr create (or as drafted, if deferred)>
    ```

    ## Checks

    - <each check reported by `gh pr checks` with its status, or "no checks configured" / "not run: <reason>">

    ## Notes

    - <anything worth recording: deferral reason, push needed, base moved, etc.>

### 6. Verify before finishing

- Re-read the written note and confirm the filename mirrors the versioning note's basename (`NNN-<slug>.md`).
- Confirm the recorded PR URL is the one `gh pr create` actually returned — or, when deferred, that the deferral and its reason are explicit and no URL was fabricated.
- Confirm `## Checks` reflects reality.

## Workflow (update mode)

When a file path to an existing PR note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/10-pr/`.
- Confirm the file exists and is a PR note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not a PR note (no `# ` title with the expected sections), report the mismatch and ask the user to confirm before editing.

### 2. Extract the follow-up conclusions

- Take the remaining arguments as the follow-up conclusions (if any were supplied). Preserve them verbatim as list items, one per conclusion.
- If no conclusions were supplied but the user referenced a prior discussion (e.g. review comments), derive them from that context; otherwise note in the Conclusions section that no conclusions were recorded yet.

### 3. Append the Conclusions section

- Read the existing note and append a `## Conclusions` section at the end.
- If the note already has a `## Conclusions` section, do not overwrite it — append the new conclusions to it, preserving the earlier ones.
- Format:

    ## Conclusions

    - <conclusion>
    - <conclusion>

- Leave all existing sections (`## Source`, `## PR`, `## Body`, `## Checks`, `## Notes`) unchanged.
- If a conclusion resolves an item previously recorded (e.g. under `## Notes`), append the conclusion and optionally strike through the resolved item (e.g. `- ~~<resolved item>~~`), leaving the item text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a list under `## Conclusions`.

## Verify before finishing

- **Create mode:** re-read the written note; confirm the basename mirrors the versioning note, the PR URL matches the PR `gh pr create` actually created (or the deferral is explicit with no fabricated URL), and the checks status is recorded accurately.
- **Update mode:** re-read the file; confirm only `## Conclusions` gained items and all pre-existing sections are untouched.

## Reporting back

- **Create mode:** tell the user the file created (full path), the PR URL (or the deferral and its reason), the checks status, and the next steps: `/resolve-conflicts` if the base branch moved ahead of the PR, `/investigate-feedback` once review comments arrive.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended.
