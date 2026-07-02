---
name: pr
description: "Generate a pull request description by filling the repo's PR template from the branch diff against main, then create or overwrite PR.md in the repo root and ask whether to create or update the GitHub PR with a title and body based on PR.md. Use whenever the user asks for a PR description, PR body, pull request summary, wants to 'write the PR', or says 'describe this branch'/'what changed since main' — even if they don't explicitly mention a template. Ask-before-run: never runs gh pr create or gh pr edit until explicit confirmation."
user-invocable: true
disable-model-invocation: false
allowed-tools: ["Bash", "Read", "Write"]
---

# /pr

Generate a pull request description by filling in the repository's PR template (`.github/PULL_REQUEST_TEMPLATE.md`) based on the diff and commit log between the current branch and `main`. **Write** the result to `PR.md` in the repo root (creating or overwriting it), draft a concise PR title from that content, then ask whether to create or update the GitHub PR with that title and `PR.md` as the body. Do not run `gh pr create` or `gh pr edit` unless the user explicitly confirms.

## Why write to PR.md

The user wants a reviewable artifact before anything changes on GitHub. Writing `PR.md` (overwriting any existing one) gives them that. Updating GitHub is useful, but it should be explicit and reviewable: print the proposed title and the exact `gh` command, then ask before running it.

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
7. **Check for an existing PR** for the current branch with `gh pr view --json number,url,title`.
   - If one exists, prepare: `gh pr edit <number> --title "<title>" --body-file PR.md`.
   - If none exists, prepare: `gh pr create --base <base> --head <current-branch> --title "<title>" --body-file PR.md`.
   - If `gh` is unavailable or the user is not authenticated, stop after writing `PR.md` and tell the user what command would have run.
8. **Ask before running gh.** Print `PR.md`, the proposed title, and the exact `gh` command in a fenced `bash` block. Ask: `Create/update this GitHub PR?` Only run the printed command if the user explicitly confirms.

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
- Never create or update a GitHub PR without explicit confirmation after showing the title and exact `gh` command.
