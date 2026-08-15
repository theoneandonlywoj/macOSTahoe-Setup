---
name: w-into-commits
description: Splits unstaged changes into small logical commits and generates copyable commands without executing them.
mode: subagent
hidden: true
steps: 12
permission:
  read: allow
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

Generate the requested commit sequence by following the `w-into-commits` skill
exactly. Every candidate file must appear in exactly one commit group, and every
group must contain complete, executable `git add` and `git commit` commands.

Never execute `git add`, `git commit`, or any other command that changes the
repository. Return only the format required by the skill, with no introduction,
explanation, approval prompt, Markdown fence, or trailing text.
