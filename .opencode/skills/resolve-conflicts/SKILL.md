---
name: resolve-conflicts
description: Use when a user invokes /resolve-conflicts, or asks to "resolve the conflicts", "rebase my branch", "sync my branch with main", "merge conflicts", or similar. Reconciles the PR branch with the moved base branch by fetching, rebasing, resolving conflicts, and re-running tests, then appends a `## Conflict resolution` section to the existing PR note in _woj/10-pr/NNN-<slug>.md.
---

# Resolve Conflicts

Reconcile the head branch of a PR with the base branch it has fallen behind, resolve any conflicts, and append a `## Conflict resolution` section to the existing PR note in `_woj/10-pr/`. This skill **appends** to a note written by `/pr-gh` — it never creates a note from scratch.

## When to use

- The user invokes `/resolve-conflicts`.
- The user asks to "resolve the conflicts", "rebase my branch", "sync my branch with the base", "fix the merge conflicts", or similar phrasing.
- The PR branch has fallen behind the base branch (e.g. GitHub reports "This branch is out-of-date" or a conflict) and the user wants it reconciled.
- The user passes a path to an existing PR note in `_woj/10-pr/` — use that note (see "Mode selection").

## Mode selection

At the start, inspect the first argument:

- If it names an existing file (absolute, repo-root-relative, or `_woj/10-pr/`-relative path to a `NNN-<slug>.md` note), use that note.
- If it names a file that does **not** exist, report an error and stop — never create a PR note from scratch.
- If no argument is given, scan `_woj/10-pr/*.md` and use the note with the highest `NNN-` prefix (the latest PR).
- If `_woj/10-pr/` is empty or missing, report that no PR is being tracked and stop.

## Workflow

### 1. Read the PR note

- Read the chosen note in full: `## Source`, `## PR` (with the PR URL and number), `## Body`, `## Checks`, and `## Notes` tell you which branch the PR tracks and what was verified.
- Note the **head branch name** of the PR (the branch that must be reconciled) and the **base branch** it targets.

### 2. Fetch and check whether the branch is behind

- Run `git fetch origin`.
- Determine whether the head branch is behind the base: check the number of commits ahead/behind (e.g. `git rev-list --count origin/<base-branch>..HEAD` for the ahead count, `git rev-list --count HEAD..origin/<base-branch>` for the behind count) and whether the base is an ancestor of HEAD (`git merge-base --is-ancestor origin/<base-branch> HEAD`).
- If the branch is up to date with the base (base is an ancestor of HEAD and no commits behind), report that no conflicts are needed and stop.

### 3. Rebase onto the base

- Prefer rebasing: `git rebase origin/<base-branch>` (rebase keeps the PR's commits cleanly on top of the updated base).
- If the rebase completes without conflicts, skip the resolution step.
- On conflict, reconcile each side:

  - List the conflicted files with `git status` (unmerged paths).
  - Open each conflicted file and resolve it, keeping the behavior intended by the spec note `_woj/05-spec/NNN-<slug>.md` with the **same basename** as the PR note. Where the spec is silent, keep the more recently intended behavior of the PR change (the base's changes are already in the branch history; the PR's change is what this branch adds).
  - Stage each resolved file with `git add <resolved files>` and continue with `git rebase --continue`.
  - If conflicts persist or the rebase stops for another reason (e.g. staged changes), inspect the state and handle it; report anything you could not resolve.

### 4. Re-run the project's tests and lint

- Find the test/lint commands in `README.md` or the `Makefile` (e.g. `make lint`, `make test`).
- Run them and record the exact commands plus their results (pass/fail and any failures) for the note and the report back.

### 5. Append the `## Conflict resolution` section

- Re-read the PR note and append a `## Conflict resolution` section at the end. If the note already has one, append to it, preserving the earlier content.
- Format:

    ## Conflict resolution

    ## Source

    <PR link: https://github.com/<owner>/<repo>/pull/<number>>

    ## Conflicts

    - <file path>: <what clashed and how it was resolved>

    ## Tests run

    - <command> — <result>
    - <command> — <result>

- Leave all existing sections (`## Source`, `## PR`, `## Body`, `## Checks`, `## Notes`) unchanged.
- Drop subsections that add no value (e.g. omit `## Conflicts` if the rebase was clean) rather than leaving them empty.

### 6. Push only with permission

- Never run `git push --force` (or `--force-with-lease`) without asking the user first — the rebase rewrites the PR branch's history, so a regular push will be rejected and a force-push requires explicit user approval.

## Verify before finishing

- Re-read the updated PR note and confirm only the `## Conflict resolution` section (or its existing equivalent) gained content; the original sections are untouched.
- Confirm the branch is ahead of the base again (e.g. `git rev-list --count origin/<base-branch>..HEAD` is non-zero and the behind count is zero).
- Confirm the tests/lint you recorded actually passed (or that failures were recorded and reported).

## Reporting back

- Tell the user which PR note was updated (full path).
- List which files conflicted and how each one was resolved.
- Report the test/lint commands run and their results.
- State whether a force-push is needed to update the PR branch, and ask the user for permission before pushing if so.
