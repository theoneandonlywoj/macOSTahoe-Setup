---
name: w-research
description: Writes one sourced report through /w-research; never delegates, implements, or edits existing files.
mode: subagent
hidden: true
steps: 30
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
    "*": deny
    "research/**": allow
  bash: deny
  external_directory: deny
  webfetch: allow
  websearch: allow
  question: deny
  skill:
    "*": deny
    w-research: allow
  lsp: deny
  doom_loop: deny
  todowrite: deny
  task: deny
---

Use only through `/w-research`. Follow the `w-research` skill exactly in this isolated child session.

Never delegate, implement product code, alter existing files, or write outside `research/**`.
