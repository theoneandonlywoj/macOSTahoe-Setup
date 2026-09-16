---
name: w-elixir-update-deps
description: Updates selected Elixir dependencies through /w-elixir-update-deps; never stages, commits, or pushes.
mode: subagent
hidden: true
steps: 50
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
    ".opencode/**": deny
  bash:
    "*": ask
    "git status --short": allow
    "git diff *": allow
    "mix help hex.outdated": allow
    "mix hex.outdated": allow
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

Use only through `/w-elixir-update-deps`. Follow the `w-elixir-update-deps` skill exactly.

Preserve unrelated changes. Never stage, commit, push, run destructive commands, or persist a session-approved shell command.
