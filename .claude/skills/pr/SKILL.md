---
name: pr
description: "Generate a GitHub pull request title and description from the branch diff, write the description to PR.md, then create or update the GitHub PR when the user invokes /pr or explicitly asks to create/update/open a PR. Use whenever the user asks for a PR description, PR body, pull request summary, wants to 'write the PR', or says 'describe this branch'/'what changed since main' — even if they don't explicitly mention a template. Description-only requests stop at PR.md unless the user confirms GitHub updates."
user-invocable: true
disable-model-invocation: false
allowed-tools: ["Bash", "Read", "Write"]
---

# /pr

Generate a GitHub pull request title and description from the current branch diff. Fill the repository's PR template (`.github/PULL_REQUEST_TEMPLATE.md`), **write** the description to `PR.md` in the repo root (creating or overwriting it), then create or update the GitHub PR with that title and `PR.md` as the body when the user invoked `/pr` or explicitly asked for GitHub PR creation/update.

## Why write to PR.md

The user needs a reviewable PR body and a repeatable GitHub update path. Writing `PR.md` (overwriting any existing one) gives them a local artifact, while `gh pr create`/`gh pr edit` publishes the same title and body to GitHub when requested. For description-only prompts, keep GitHub side effects behind an explicit confirmation.

## Workflow

1. **Locate the template.** Read `.github/PULL_REQUEST_TEMPLATE.md` (repo root). If it doesn't exist, fall back to the standard structure documented in `references` below and tell the user you're doing so.
2. **Gather the branch context.** Run from the repo root:
   - `git rev-parse --abbrev-ref HEAD` — current branch name.
   - `git log main..HEAD --oneline` — commits on this branch (the "what").
   - `git diff main...HEAD --stat` — file-level change summary.
   - `git diff main...HEAD` — the full diff (read in chunks if large; the `--stat` is usually enough to drive the description, dip into the full diff for detail).
   - If `main` doesn't exist locally, try `origin/main`. If neither resolves, ask the user for the base branch.
3. **Fill the template.** For each section in the template, derive content from the commits + diff:
   - **Summary** — 1–3 sentences distilling the branch's purpose, drawn from the dominant theme of the commit messages.
   - **Motivation / Context** — infer the *why* from commit bodies and the nature of the change. If unclear, write a best-effort sentence flagged with "(confirm)" so the user can verify.
   - **Changes** — bullet list, one per logical change, mapped from commits and the `--stat`. Reference file paths parenthetically.
   - **Type of change** — pick the dominant Conventional Commits type (`feat`/`fix`/`docs`/`refactor`/`chore`/`test`/`perf`/`build`/`ci`), plus a `BREAKING` flag if the diff removes/renames public surface.
   - **Checklist** — leave the template's checkboxes for the user to tick, but pre-check the ones clearly satisfied by the diff (e.g. if tests were added, check "tests added").
4. **Preserve template structure.** Keep the template's headings, order, and checkbox syntax (`- [ ]`/`- [x]`) exactly. Only fill in content under each heading — don't rewrite the template.
5. **Write** the filled-in description to `PR.md` in the repo root, creating or overwriting that file.
6. **Draft a title** from the PR body and branch diff. Keep it concise and imperative or noun-phrase style, e.g. `Add AI coding skills and sync targets`. Do not use markdown in the title.
7. **Decide whether to touch GitHub.** Invoking `/pr` or asking to create/update/open/publish the PR counts as explicit permission to run `gh`. If the user only asked for a description, body, summary, or `PR.md`, print `PR.md`, the proposed title, and the exact `gh` command you would run, then ask before continuing.
8. **Create or update the GitHub PR when permitted.**
   - Require GitHub CLI authentication first: run `gh auth status`. If it fails, tell the user to run `gh auth login` and stop without creating or updating the PR.
   - Check for an existing PR for the current branch with `gh pr view --json number,url,title`. A "no pull requests found" result means create a new PR; authentication, network, and repository errors are failures.
   - If one exists, run `gh pr edit <number> --title "<title>" --body-file PR.md`, then get the URL with `gh pr view <number> --json url --jq .url`.
   - If none exists, run `gh pr create --base <base> --head <current-branch> --title "<title>" --body-file PR.md` and capture the URL printed by `gh`.
   - If `gh` is unavailable, `gh auth status` fails, the branch cannot be pushed, or the command fails, stop and report the failed command plus the local `PR.md` path. Do not claim the PR was created or updated unless `gh` succeeds.
9. **Report the result.** Print the `PR.md` path, the title used, whether the PR was created or updated, and the GitHub PR URL when available.

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

- Base everything on `main..HEAD`. Don't describe uncommitted local changes.
- If the branch is a single commit, the description can be short — don't pad.
- If the branch mixes many unrelated changes, say so and suggest splitting.
- Keep it honest: don't claim tests were added if the diff doesn't show them.
- The user must be authenticated with GitHub CLI via `gh auth login` before the skill can create or update a PR.
- Treat `/pr` and explicit create/update/open/publish requests as permission to run `gh pr create` or `gh pr edit`; for description-only requests, ask before touching GitHub.
