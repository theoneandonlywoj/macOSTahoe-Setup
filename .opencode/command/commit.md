---
description: Generate a commit message from staged changes and commit after user approval
---

Generate a commit message from the currently staged changes (files added with `git add <file>`), show it to the user, and commit only after explicit approval.

Follow these steps exactly:

1. Run `git diff --cached --stat` to see which files are staged. If the diff is empty, run `git status --short` to confirm. If nothing is staged, tell the user nothing is staged and that they should run `git add <file>` first, then stop.
2. Run `git diff --cached` to read the full staged diff and summarize the change.
3. Write one commit message in this repository's style: conventional prefixes (`feat:`, `fix:`, `chore:`, `docs:`, `other:`, `conf:`, etc.) followed by an imperative summary. Chain multiple prefixes with `+` when the change spans several types, e.g. `docs+chore: ...`, `feat+fix: ...` (as in existing commits like `feat+docs: herdr configuration and docs`).
4. Show the proposed commit message to the user and wait for explicit acceptance. Do NOT commit yet.
5. Only after the user explicitly approves, run the commit with the author and date set explicitly:
   ```
   git commit -m "<message>" --author="$(git config user.name) <$(git config user.email)>" --date="$(date +%Y-%m-%dT%H:%M:%S%z)"
   ```
   Resolve `git config user.name` and `git config user.email` from the repo config and use the current time as the date.

Never run `git commit` before the user has approved the message, and never add `Co-authored-by:` trailers or any other agent attribution to the commit message.