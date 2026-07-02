---
description: Generate a PR description from the branch diff, write PR.md, then ask whether to create or update the GitHub PR with that body and title
---

Current branch commits since main:

!`git log main..HEAD --oneline`

File-level changes vs main:

!`git diff main...HEAD --stat`

Generate a pull request description by filling in `.github/PULL_REQUEST_TEMPLATE.md` (read it from the repo root). If that file doesn't exist, use this standard structure instead: Summary, Motivation/Context, Changes, Type of change, Checklist.

Rules:
- Derive every section from the commits and diff above. Don't describe uncommitted local changes.
- **Summary**: 1–3 sentences distilling the branch purpose.
- **Motivation / Context**: the *why*; flag uncertain inferences with "(confirm)".
- **Changes**: one bullet per logical change, with file paths parenthetically.
- **Type of change**: dominant Conventional Commits type (`feat`/`fix`/`docs`/`refactor`/`chore`/`test`/`perf`/`build`/`ci`), plus `BREAKING` if public surface changed.
- Preserve the template's headings, order, and `- [ ]` checkbox syntax exactly; only fill content under each heading.
- Create or overwrite `PR.md` in the repo root with the filled description.
- Draft a concise PR title from the PR body and branch diff. Keep it plain text, no markdown.
- Check whether the current branch already has a GitHub PR with `gh pr view --json number,url,title`.
- If a PR exists, prepare `gh pr edit <number> --title "<title>" --body-file PR.md`.
- If no PR exists, prepare `gh pr create --base main --head <current-branch> --title "<title>" --body-file PR.md`.
- If `main` is not the base branch, use the same base branch used for the diff.
- Print the path `PR.md`, the proposed title, and the exact `gh` command in a fenced `bash` block.
- Ask `Create/update this GitHub PR?` Do not run `gh pr create` or `gh pr edit` unless the user explicitly confirms.
