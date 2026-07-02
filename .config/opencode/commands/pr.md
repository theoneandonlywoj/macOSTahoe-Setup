---
description: Generate a PR description by filling the repo's PR template from the branch diff vs main and write PR.md
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
- Do not run `gh pr create`.
- After writing the file, print only the path `PR.md` and a one-line confirmation.
