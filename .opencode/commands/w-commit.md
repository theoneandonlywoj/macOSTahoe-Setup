---
description: Generate a commit message and git commit command from staged changes without executing it
model: opencode/deepseek-v4-flash-free
agent: w-commit
subtask: true
---

Generate a commit message and show the complete, copyable `git commit` command from
the staged changes. Follow the w-commit skill exactly. The `Command:` section must
contain the actual command, not text saying that it was provided or not executed.
Never execute the command, ask for approval, or return anything outside the required
Files, Message, and Command sections.
