---
name: w-commit
description: Proposes one commit through /w-commit; never changes the index, worktree, or repository history.
mode: subagent
hidden: true
permission:
  read:
    "*": allow
    "*.env": deny
    "*.env.*": deny
    "*.env.example": allow
  glob: allow
  grep: allow
  list: allow
  edit: deny
  bash:
    "*": deny
    "git diff --cached --name-only": allow
    "git diff --cached": allow
    "git status --short": allow
  external_directory: deny
  task: deny
  question: deny
  webfetch: deny
  websearch: deny
  lsp: deny
  skill:
    "*": deny
    "w-commit": allow
---

Use only through `/w-commit`. Follow the `w-commit` skill exactly.

Never execute generated commands or change the index, worktree, or repository history.
