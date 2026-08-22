---
name: w-commit
description: Generate a commit proposal from staged changes. Use only when the user runs /w-commit.
---

Follow these steps exactly:

1. Run `git diff --cached --name-only` to list the staged files. If the output is empty, run `git status --short` to confirm. If nothing is staged, tell the user nothing is staged and that they should run `git add <file>` first, then stop.
2. Run `git diff --cached` and summarize the change internally.
3. Write one commit message in this repository's style: conventional prefixes (`feat:`, `fix:`, `chore:`, `docs:`, `other:`, `conf:`, etc.) followed by an imperative summary. Chain prefixes with `+` only when one coherent change genuinely spans types. Keep the message on one line. Do not use double quotes, backticks, dollar signs, backslashes, control characters, or newlines in it.
4. Return only the following plain-text format. Do not add an introduction, summary, approval prompt, Markdown fence, or trailing text:

   ```text
   Files:
   - <file>
   - <file>

   Message:
   <commit message>

   Command:
   git commit -m "<message>" --author="$(git config user.name) <$(git config user.email)>" --date="$(date +%Y-%m-%dT%H:%M:%S%z)"
   ```

   Replace each placeholder with the actual staged file or generated commit message. The `Command:` section must contain the complete executable command shown above. Keep the safely generated message, author substitution, and date substitution exactly as shown.

Never run `git commit`, never ask for approval, and never add `Co-authored-by:` trailers or any other agent attribution to the commit message.
