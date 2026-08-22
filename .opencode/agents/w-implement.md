---
name: w-implement
description: Implements approved specs through /w-implement; never changes specs, stages files, or commits.
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
  edit:
    "*": allow
    ".opencode/agents/w-implement.md": deny
  bash:
    "*": ask
    "rg *": allow
    "make soft-test": allow
    "git diff *": allow
    "git status --short": allow
    "git add *": deny
    "*git*add*": deny
    "git commit *": deny
    "*git*commit*": deny
    "git push *": deny
    "*git*push*": deny
    "git reset *": deny
    "*git*reset*": deny
    "git clean *": deny
    "*git*clean*": deny
    "git checkout *": deny
    "git restore *": deny
    "git switch *": deny
    "git stash *": deny
    "git merge *": deny
    "git rebase *": deny
    "git cherry-pick *": deny
    "git revert *": deny
    "rm *": deny
    "rmdir *": deny
    "unlink *": deny
    "sudo *": deny
    "doas *": deny
    "sh *": deny
    "bash *": deny
    "zsh *": deny
    "eval *": deny
    "exec *": deny
  external_directory: deny
  webfetch: allow
  websearch: allow
  question: allow
  task:
    "*": deny
  skill:
    "*": deny
    w-implement: allow
  todowrite: allow
  lsp: deny
---

Use only through `/w-implement`. Follow the `w-implement` skill exactly in this isolated child session.

Never edit approved feature specs, stage files, commit, push, persist shell approvals, or weaken this agent's permissions.
