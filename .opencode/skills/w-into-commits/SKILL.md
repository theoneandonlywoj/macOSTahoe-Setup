---
name: w-into-commits
description: Split unstaged changes into commit proposals. Use only when the user runs /w-into-commits.
---

# Split Changes Into Commits

Follow these steps exactly:

1. Run `git diff --cached --name-only`. Intent-to-add entries created by
   `git add -N` do not appear in this output. If the output is not empty, stop
   and return only:

   ```text
   Cannot generate a safe commit sequence while the index contains staged content.
   Unstage or commit the currently staged changes, then run /w-into-commits again.
   ```

   Do not generate commands that could accidentally include existing staged
   content, and never unstage it yourself.
2. Run `git diff --name-only` to list every unstaged candidate path. This includes
   tracked modifications and untracked files previously exposed with
   `git add -N <files>`. If the output is empty, run `git status --short` to
   confirm, then return only:

   ```text
   No unstaged changes are available. Use git add -N <files> to expose untracked files, then run /w-into-commits again.
   ```

3. Run `git diff --no-ext-diff` to inspect the complete candidate changes and
   `git log --oneline -20` to inspect recent commit-message style.
4. Partition the candidate files into the smallest coherent, reviewable commits:
   - Assign every candidate file to exactly one commit and do not omit or
     duplicate paths.
   - Group by one logical purpose, not merely by directory or file type.
   - Keep implementation with its directly associated tests, migrations,
     configuration, and documentation when separating them would make a commit
     incomplete or invalid.
   - Put prerequisites before their consumers so the generated sequence can be
     run from top to bottom.
   - Do not split a file by hunk and do not generate `git add -p` commands. If one
     file contains several concerns, place the whole file in the most coherent
     group and keep the limitation visible through that group's message.
5. Write one message for each group in this repository's style: conventional
   prefixes (`feat:`, `fix:`, `chore:`, `docs:`, `other:`, `conf:`, etc.) followed
   by an imperative summary. Chain prefixes with `+` only when one coherent group
   genuinely spans types, as in `docs+chore: ...`. Keep each message on one line
   and do not use double quotes, backticks, dollar signs, or backslashes in it.
6. Shell-quote every path in each `git add` command and include `--` before its
   pathspecs. Use single quotes, escaping any embedded single quote with the
   standard `'\''` shell sequence. Never generate wildcard pathspecs.
7. Return only the following plain-text format, repeating the complete block for
   every group in execution order. Do not add an introduction, summary, approval
   prompt, Markdown fence, or trailing text:

   ```text
   Commit 1:

   Files:
   - <file>
   - <file>

   Message:
   <commit message>

   Commands:
   git add -- '<file>' '<file>'
   git commit -m "<message>" --author="$(git config user.name) <$(git config user.email)>" --date="$(date +%Y-%m-%dT%H:%M:%S%z)"

   Commit 2:

   Files:
   - <file>

   Message:
   <commit message>

   Commands:
   git add -- '<file>'
   git commit -m "<message>" --author="$(git config user.name) <$(git config user.email)>" --date="$(date +%Y-%m-%dT%H:%M:%S%z)"
   ```

   Replace every placeholder with an actual candidate path or generated message.
   Number groups consecutively from 1. The command section must contain complete
   executable commands, not descriptions or disclaimers. Keep the author and date
   command substitutions exactly as shown.

Never run `git add`, `git commit`, or any generated command. Never ask for
approval, change the repository, add `Co-authored-by:` trailers, or add any other
agent attribution.
