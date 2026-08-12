---
name: code-versioning-organisation
description: Use when a user invokes /code-versioning-organisation, asks to "organize the commits", "plan the commits", "how should I commit this", "split this into commits", or similar. Reads the approved code-quality note from _woj/08-code-quality/, applies the commit-conventions skill, and writes a branch and commit plan to _woj/09-code-versioning/NNN-<slug>.md without committing anything. Also use when a file path to an existing versioning note is passed (or the user wants to append follow-up conclusions): append a Conclusions section to that note.
---

# Code Versioning Organisation

Plan the branch name and the commit sequence for an approved feature — without committing anything. The plan is grounded in the code-quality note from `_woj/08-code-quality/`, every commit message follows the commit-conventions skill, and the result is written to `_woj/09-code-versioning/`. Actual committing is done separately via `/commit`.

## When to use

- The user invokes `/code-versioning-organisation`.
- The user asks to "organize the commits", "plan the commits", "how should I commit this", "split this into commits", "what branch should I use", or similar phrasing.
- The user passes a file path to an existing versioning note (e.g. `/code-versioning-organisation _woj/09-code-versioning/002-...md <conclusions>`), or asks to "update the plan with conclusions", "append conclusions". This is **update mode** — see "Workflow (update mode)".

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/09-code-versioning/`-relative path to a `NNN-<slug>.md` note), use **update mode**.
- If it names a file that does **not** exist, report an error; do not create a new file from a path argument.
- Otherwise, use **create mode** (default).

## Workflow (create mode)

### 1. Read the quality note

- If the user named a note, use it. Otherwise use the note with the highest `NNN-` prefix in `_woj/08-code-quality/` (the latest one).
- Read the note in full and confirm its `## Verdict` is `approve`.
- If the verdict is `changes-requested` (or no verdict is present), do not plan commits — tell the user to run `/implement` (or `/implement-feedback`) first and stop.

### 2. Read the commit-conventions skill

- Read `.opencode/skills/commit-conventions/SKILL.md` in full before drafting anything.
- Apply its rules to every planned message: required type, optional scope, `!` or `BREAKING CHANGE:` footer for breaking changes, imperative subject under ~50 characters, body, and footers.
- Every commit message in the plan MUST be valid per that skill — no exceptions.

### 3. Inspect git state

Run and read:

- `git status` — changed, staged, and untracked files.
- `git diff` (or `git diff --cached` if changes are already staged).
- `git log --oneline -10` — recent history for message style.
- `git branch --show-current` — the current branch name.

### 4. Decide the branch name

- Derive it from the feature slug: `feat/<slug>` (e.g. slug `setup-logging` → `feat/setup-logging`).
- If already on that branch, note it in the plan. Otherwise propose creating and checking it out (e.g. `git checkout -b feat/<slug>`).
- **Propose only — do not commit and do not switch branches yourself.**

### 5. Split the changes into logical commits

- Group every changed file into commits, each with one cohesive intent.
- Assign each file to exactly one commit; use the diff to find the seams (e.g. docs vs. implementation vs. tests).
- If the working tree contains unrelated changes, leave them out of the plan and flag them in the `## Checklist` instead of forcing them into a commit.

### 6. Write the versioning note

Write to `_woj/09-code-versioning/NNN-<slug>.md` where:

- `NNN` and `<slug>` **mirror the source quality note's basename** (e.g. `_woj/08-code-quality/002-setup-logging.md` produces `_woj/09-code-versioning/002-setup-logging.md`), making the chain traceable.
- When there is no quality note, scan `_woj/09-code-versioning/*.md` for the highest existing `NNN-` prefix, add 1, and zero-pad to 3 digits (start at `001` if empty). Use a kebab-case slug of the change.

Create `_woj/09-code-versioning/` if it does not exist. Never overwrite an existing file — the sequence number guarantees uniqueness.

### 7. Note template

A note is Markdown; all fenced blocks use triple backticks. **Drop sections that add no value** (`Rationale` under `## Branch`) rather than leaving them empty.

```markdown
# <Short imperative title>

## Source

Quality note: `_woj/08-code-quality/NNN-<slug>.md`

## Branch

- `feat/<slug>` — <one-line rationale>

## Commit plan

1. `feat(<scope>): <imperative subject>`

   - Files: `path/one.zsh`, `path/two`
   - Why: <one-line rationale>

2. `docs: <imperative subject>`

   - Files: `README.md`
   - Why: <one-line rationale>

## Checklist

- [ ] Tests pass (`make test` or the repo's test command)
- [ ] No secrets or credentials in the diff
- [ ] No unrelated files in the working tree
```

### 8. Present the plan

- Summarize the branch and the ordered commit plan to the user and ask for confirmation.
- State that actual committing is done separately via `/commit` — this skill never runs `git commit` itself.

## Workflow (update mode)

When a file path to an existing versioning note is provided:

### 1. Resolve and validate the path

- Accept absolute paths, paths relative to the repository root, and paths relative to `_woj/09-code-versioning/`.
- Confirm the file exists and is a versioning note. If it does not exist, report an error and stop — never create a new note from an update invocation.
- If the file exists but is not a versioning note (no `# ` title with a `## Commit plan` section), report the mismatch and ask the user to confirm before editing.

### 2. Extract the follow-up conclusions

- Take the remaining arguments as the follow-up conclusions (if any were supplied). Preserve them verbatim as list items, one per conclusion.
- If no conclusions were supplied but the user referenced a prior discussion, derive them from that context; otherwise note in the Conclusions section that no conclusions were recorded yet.

### 3. Append the Conclusions section

- Read the existing note and append a `## Conclusions` section at the end.
- If the note already has a `## Conclusions` section, do not overwrite it — append the new conclusions to it, preserving the earlier ones.
- Format:

```markdown
## Conclusions

- <conclusion>
- <conclusion>
```

- Leave all existing sections (`## Source`, `## Branch`, `## Commit plan`, `## Checklist`) unchanged.
- If a conclusion resolves an item previously listed under `## Commit plan`, append the conclusion and optionally strike through the resolved item (e.g. `- ~~<resolved item>~~`), leaving the text in place.

### 4. Verify before finishing

- Re-read the file and confirm the original content is untouched and only `## Conclusions` (or its existing section) gained the new items.
- Confirm conclusions are stored as a list under `## Conclusions`.

## Verify before finishing

- Re-read the written file and confirm the filename mirrors the source quality note (`NNN-<slug>.md`).
- Confirm every commit message in the plan follows the commit-conventions skill (type, scope, `!`, imperative subject, body/footers).
- Confirm every changed file from `git status` is assigned to exactly one commit in the plan.

## Reporting back

- **Create mode:** tell the user the file created (full path), the branch name, the number of planned commits, and that the next step is `/pr-gh`. If the working tree had unrelated changes, flag them so the user can clean up before committing.
- **Update mode:** tell the user which file was updated (full path) and summarize the conclusions appended. If any commit-plan items were resolved and struck through, mention them.
