---
description: Review, select, update, and document Elixir dependencies
agent: w-elixir-update-deps
subtask: false
---

[w-elixir-update-deps:start]

Inspect the Mix project for outdated dependencies. List dependencies marked as
update possible and dependencies blocked by current constraints, then ask in a
normal chat message whether to update all available dependencies or specific
package names. Never use a popup or the question tool. Stop and wait for the
user's chat reply before changing files.

After the user selects dependencies, follow the w-elixir-update-deps skill
exactly through updating, verification, upstream release research, impact and
risk analysis, and PR.md generation. Never commit or push changes.
