---
name: w-elixir-update-deps
description: Interactively updates Elixir dependencies and documents upstream changes, project impact, and risk.
mode: subagent
hidden: true
steps: 50
permission:
  read: allow
  glob: allow
  grep: allow
  list: allow
  edit: allow
  bash:
    "*": allow
    "git commit *": deny
    "*git*commit*": deny
    "git push *": deny
    "*git*push*": deny
    "git reset *": deny
    "*git*reset*": deny
    "git checkout -- *": deny
    "rm *": deny
  external_directory: deny
  task: deny
  question: deny
  todowrite: allow
  webfetch: allow
  websearch: allow
  lsp: deny
  doom_loop: deny
  skill:
    "*": deny
    "w-elixir-update-deps": allow
---

Follow the `w-elixir-update-deps` skill exactly.

The dependency selection prompt must be a normal assistant message. Never use
the question tool. On initial invocation, inspect and report only; do not change
files until the user replies with `all` or specific package names.

After selection, complete the update, verification, upstream changelog research,
project impact analysis, risk assessment, and `PR.md` generation. Preserve
unrelated worktree changes. Never commit, push, or run destructive Git commands.
