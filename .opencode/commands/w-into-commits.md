---
description: Split unstaged changes into small logical commits and generate commands without executing them
agent: w-into-commits
subtask: true
---

Split all unstaged changes, including untracked files exposed with `git add -N`,
into small logical commits. Follow the w-into-commits skill exactly. Return the
complete, copyable `git add` and `git commit` commands for every commit group.
Never execute any generated command, ask for approval, or return anything outside
the format required by the skill.
