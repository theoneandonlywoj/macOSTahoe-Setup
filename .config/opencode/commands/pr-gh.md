---
description: Generate a PR title and description from the branch diff, write PR.md, then create or update the GitHub PR after verifying gh authentication
---

Current branch commits since main:

!`git log main..HEAD --oneline`

Current branch name:

!`git rev-parse --abbrev-ref HEAD`

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
- Treat this `/pr` command invocation as explicit permission to run `gh pr create` or `gh pr edit` after authentication succeeds.
- Require GitHub CLI authentication before touching GitHub: run `gh auth status`. If it fails, tell the user to run `gh auth login` and stop without creating or updating the PR.
- Check whether the current branch already has a GitHub PR with `gh pr view --json number,url,title`. A "no pull requests found" result means create a new PR; authentication, network, and repository errors are failures.
- If a PR exists, run `gh pr edit <number> --title "<title>" --body-file PR.md`, then get the URL with `gh pr view <number> --json url --jq .url`.
- If no PR exists, run `gh pr create --base main --head <current-branch> --title "<title>" --body-file PR.md` and capture the URL printed by `gh`.
- If `main` is not the base branch, use the same base branch used for the diff.
- After success, print the path `PR.md`, the title used, whether the PR was created or updated, and the GitHub PR URL.
- If `gh` is unavailable, `gh auth status` fails, branch push is required but unavailable, or any GitHub command fails, stop and report the failed command plus the local `PR.md` path.
