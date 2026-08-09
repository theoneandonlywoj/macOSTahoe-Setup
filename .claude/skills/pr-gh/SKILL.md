---
name: pr
description: "Generate a pull request title and body from the current branch diff, write PR.md, then create or update the GitHub PR when the user invokes /pr or asks to create/open/update a PR. Use whenever the user asks for a PR description, PR body, pull request summary, branch summary, or says 'write the PR'/'describe this branch' - even if they do not mention a template. For publish requests, authenticate gh first, push the current branch to origin when needed, then run gh pr create/edit."
user-invocable: true
disable-model-invocation: false
allowed-tools: ["Bash", "Read", "Write", "Glob"]
---

# /pr

Create a reviewable pull request description from the committed branch diff and, when requested, publish it to GitHub.

## Outcomes

- Always write or overwrite `PR.md` in the repository root with the PR body.
- Draft a concise plain-text PR title.
- If the user invoked `/pr` or explicitly asked to create, open, publish, or update a PR, authenticate GitHub CLI, ensure the current branch exists on `origin`, then create or update the GitHub PR.
- If the user only asked for a title/body/summary, stop after writing `PR.md` and print the GitHub command that would be run.

## Safety Rules

- Base the PR body only on committed changes in the current branch compared with the base branch. Do not describe unstaged or uncommitted files, including `PR.md` itself.
- Never run `git add`, `git commit`, rebase, reset, checkout, or force-push.
- Before any GitHub operation, run `gh auth status`. If it fails, tell the user to run `gh auth login` and stop.
- `gh pr create` requires the head branch to exist on GitHub. For publish requests, pushing the current branch to `origin` is allowed after authentication. Use a normal push only: `git push -u origin HEAD:"<current-branch>"`. If that push fails, stop and report the failed command plus `PR.md`.
- Do not claim a PR was created or updated unless the relevant `gh` command succeeds.

## Workflow

### 1. Establish repository context

Run from the repository root:

```bash
git rev-parse --show-toplevel
git rev-parse --abbrev-ref HEAD
git status --short
```

Use the current branch as the PR head. If the current branch is `HEAD`, detached, or the same as the base branch, stop and ask for the intended branch.

Choose the base branch this way:

1. Use the base branch named by the user, if provided.
2. Otherwise use `main` if it exists locally.
3. Otherwise use `origin/main` for diffing and `main` for `gh --base` if `origin/main` exists.
4. Otherwise try `master`, then `origin/master`.
5. If none exists, ask the user for the base branch.

Keep both values when they differ:

- Diff base ref: the local ref used in `git log` and `git diff`, such as `main` or `origin/main`.
- GitHub base branch: the branch name passed to `gh pr create --base`, such as `main`.

### 2. Gather only committed branch changes

Run:

```bash
git log <diff-base-ref>..HEAD --oneline
git diff <diff-base-ref>...HEAD --stat
git diff <diff-base-ref>...HEAD
```

If `git log <diff-base-ref>..HEAD --oneline` is empty, stop: there are no committed branch changes to describe.

Ignore `git status --short` entries when writing the PR body. Mention uncommitted files only if they may surprise the user, for example: `PR.md is local only and is not part of the branch diff.`

### 3. Load the PR template

Look for `.github/PULL_REQUEST_TEMPLATE.md` in the repository root.

- If it exists, read it and preserve its headings, order, comments, and checkbox syntax.
- If it does not exist, use the standard fallback structure below.

### 4. Fill the body

Derive every section from the commits and branch diff.

- **Summary**: 1-3 sentences that distill the branch purpose.
- **Motivation / Context**: explain why the change exists. If the reason is inferred rather than proven by commits or diff, add `(confirm)`.
- **Changes**: one bullet per logical change, with file paths in parentheses.
- **Type of change**: dominant Conventional Commits type: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `perf`, `build`, or `ci`. Add `BREAKING` only if the branch changes public surface incompatibly.
- **Checklist**: preserve the template's `- [ ]` syntax. Pre-check an item only when the diff clearly proves it.

For custom templates, fill content under the existing headings without rewriting the template. If a required concept has no matching heading, put the content under the closest existing heading instead of adding a new one.

### 5. Write `PR.md` and title

Write the completed PR body to `PR.md` in the repository root.

Draft a concise plain-text title from the branch diff and PR body. Prefer an imperative phrase or short noun phrase, for example `Add guide creation skill`. Do not include Markdown.

### 6. Stop for description-only requests

If the user asked only for a PR description, body, title, summary, or `PR.md`, do not touch GitHub. Print:

- `PR.md`
- the proposed title
- the exact `gh pr create` or `gh pr edit` command that would be run
- a short question asking whether to publish it

### 7. Authenticate before GitHub operations

For `/pr` and explicit create/open/publish/update requests, run:

```bash
gh auth status
```

If this fails or `gh` is unavailable, stop. Tell the user to run `gh auth login`, and report that `PR.md` was written locally.

### 8. Check for an existing PR

Run:

```bash
gh pr view --json number,url,title
```

Interpret results carefully:

- If it returns PR JSON, update that PR.
- If it says no pull requests were found for the branch, create a new PR.
- Any authentication, network, repository, or parsing error is a failure. Stop and report the failed command plus `PR.md`.

### 9. Update an existing PR

If a PR exists, run:

```bash
gh pr edit <number> --title "<title>" --body-file PR.md
gh pr view <number> --json url --jq .url
```

Report the URL from the second command.

### 10. Publish the branch before creating a PR

If no PR exists, push the committed current branch to `origin` before `gh pr create`:

```bash
git remote get-url origin
git push -u origin HEAD:"<current-branch>"
```

This step prevents `gh pr create` failures such as `Head sha can't be blank`, `Base sha can't be blank`, `No commits between main and <branch>`, or `Head ref must be a branch` when the branch exists only locally.

If the push fails, stop. Report the failed command and the local `PR.md` path. Do not force-push or try to repair divergent history automatically.

After the push succeeds, run `gh pr view --json number,url,title` one more time. If it now returns a PR, update that PR instead of creating a duplicate.

If no PR exists after the push, create the PR:

```bash
gh pr create --base "<github-base-branch>" --head "<current-branch>" --title "<title>" --body-file PR.md
```

Capture the URL printed by `gh`.

### 11. Final report

After success, print:

- `PR.md`
- the title used
- whether the PR was created or updated
- the GitHub PR URL

If any command fails after `PR.md` is written, stop and report:

- the failed command
- the error output
- the local `PR.md` path
- the title that would have been used

## Standard fallback structure

Use this only when no `.github/PULL_REQUEST_TEMPLATE.md` is found:

```markdown
## Summary
<!-- 1-3 sentences -->

## Motivation / Context
<!-- why -->

## Changes
- <!-- bullet per logical change (path) -->

## Type of change
<!-- feat | fix | docs | refactor | chore | test | perf | build | ci | breaking -->

## Checklist
- [ ] Tests added/updated
- [ ] Docs updated
- [ ] Migration notes (if breaking)
```

## Notes

- If the branch is a single commit, keep the PR body short. Do not pad.
- If the branch mixes unrelated changes, say so and suggest splitting.
- Keep it honest: don't claim tests were added if the diff doesn't show them.
- Treat `/pr` and explicit create/update/open/publish requests as permission to run `gh pr create` or `gh pr edit` after authentication, and as permission to run the normal branch push needed for `gh pr create`.
- For description-only requests, ask before touching GitHub or pushing.
