---
description: Generate a short conventional git commit -m command from staged changes, then ask whether to run it
---

Review the staged changes in this repository:

!`git diff --staged`

Generate a short **Conventional Commits** message based on this diff, print a ready-to-run `git commit -m ...` command, then ask whether to run it. Do not run `git commit` unless the user explicitly confirms. Never run `git add`.

Rules:
- Subject line: `<type>(<optional scope>): <imperative summary in lowercase>`, ≤72 chars, no trailing period.
- Type is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Keep the command short: use a subject-only commit by default.
- Add a footer only when required for `BREAKING CHANGE:` or issue refs (`Closes #N`).
- Output a shell command: `git commit -m "<subject>"` for normal commits, or one additional `-m "<footer>"` when a footer is required.
- Escape embedded double quotes, backslashes, dollar signs, and backticks so the command is safe to paste into a shell.
- Base the message **only** on the staged diff above. If the diff is empty, say "Nothing is staged — nothing to commit." and stop.

Output the short command in a fenced `bash` code block, then ask: `Run this commit command?`
