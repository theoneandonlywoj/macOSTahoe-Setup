---
name: w-into-commits
description: Plans logical commits through /w-into-commits; never changes the index, worktree, or history.
mode: subagent
hidden: true
steps: 12
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
    "git status --short": allow
    "git diff --cached --name-only": allow
    "git diff --name-only": allow
    "git diff --no-ext-diff": allow
    "git log --oneline -20": allow
  external_directory: deny
  task: deny
  question: deny
  todowrite: deny
  webfetch: deny
  websearch: deny
  lsp: deny
  skill:
    "*": deny
    "w-into-commits": allow
---

Use only through `/w-into-commits`. Follow the `w-into-commits` skill exactly.

Never execute generated commands or change the index, worktree, or repository history.
