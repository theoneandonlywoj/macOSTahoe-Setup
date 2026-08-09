---
description: Create or update a GitHub PR directly from the branch diff (no PR.md) — title and body from the committed changes, using .github/PULL_REQUEST_TEMPLATE.md or the repo's recently merged PRs for structure, then gh pr create/edit after verifying gh auth
---

Current branch commits since main:

!`git log main..HEAD --oneline`

Current branch name:

!`git rev-parse --abbrev-ref HEAD`

File-level changes vs main:

!`git diff main...HEAD --stat`

Generate a pull request title and body from the commits and diff above. Fill the body using `.github/PULL_REQUEST_TEMPLATE.md` (read it from the repo root) if it exists; otherwise run `gh pr list --state merged --base main --limit 5 --json number,title,body`, read 1-3 of the returned bodies, and mirror their heading structure, tone, and checklist style; if there are no merged PRs, use this standard structure instead: Summary, Motivation/Context, Changes, Type of change, Checklist.

Rules:
- Derive every section from the commits and diff above. Don't describe uncommitted local changes.
- **Summary**: 1–3 sentences distilling the branch purpose.
- **Motivation / Context**: the *why*; flag uncertain inferences with "(confirm)".
- **Changes**: one bullet per logical change, with file paths parenthetically.
- **Type of change**: dominant Conventional Commits type (`feat`/`fix`/`docs`/`refactor`/`chore`/`test`/`perf`/`build`/`ci`), plus `BREAKING` if public surface changed.
- Preserve the template's headings, order, and `- [ ]` checkbox syntax exactly; only fill content under each heading.
- Draft a concise PR title from the PR body and branch diff. Keep it plain text, no markdown.
- Do NOT create or write `PR.md` or any other file in the repository. Write the body to a temp file with `mktemp` (e.g. `/tmp/pr-body-XXXX.md`), use it with `gh pr create`/`gh pr edit` via `--body-file`, and delete it afterwards in every path.
- Treat this `/pr-gh` command invocation as explicit permission to run `gh pr create` or `gh pr edit` after authentication succeeds.
- Require GitHub CLI authentication before touching GitHub: run `gh auth status`. If it fails, tell the user to run `gh auth login` and stop without creating or updating the PR.
- Check whether the current branch already has a GitHub PR with `gh pr view --json number,url,title`. A "no pull requests found" result means create a new PR; authentication, network, and repository errors are failures.
- If a PR exists, run `gh pr edit <number> --title "<title>" --body-file <temp>`, then get the URL with `gh pr view <number> --json url --jq .url`.
- If no PR exists, run `gh pr create --base main --head <current-branch> --title "<title>" --body-file <temp>` and capture the URL printed by `gh`.
- If `main` is not the base branch, use the same base branch used for the diff.
- After success, print the title used, whether the PR was created or updated, and the GitHub PR URL, then delete the temp file.
- If `gh` is unavailable, `gh auth status` fails, branch push is required but unavailable, or any GitHub command fails, stop, report the failed command, and delete the temp file.
