# Lazygit Actions Guide

A practical shortcut-first guide to lazygit: common Git actions, hunk staging, branches, worktrees, history cleanup, and safe recovery.

---

## Table of Contents

1. [What is lazygit?](#what-is-lazygit)
2. [Installation](#installation)
3. [Core Concepts](#core-concepts)
4. [Navigation](#navigation)
5. [Common Actions](#common-actions)
6. [Files, Hunks, and Lines](#files-hunks-and-lines)
7. [Commit and Push Actions](#commit-and-push-actions)
8. [Branches](#branches)
9. [Worktrees](#worktrees)
10. [Stash](#stash)
11. [History Cleanup](#history-cleanup)
12. [Pull Requests](#pull-requests)
13. [Quick Reference](#quick-reference)
14. [Troubleshooting](#troubleshooting)

---

## What is lazygit?

**lazygit** is a terminal UI for Git. It gives you panels for files, branches, commits, stash entries, remotes, tags, and worktrees so you can do common Git work without remembering every Git command.

Think of it as a keyboard-driven Git dashboard: select something on the left, inspect details on the right, then press one key to act.

**Why you need it:**

- Stage individual files, hunks, or lines faster than `git add -p`
- Commit, push, pull, fetch, and stash without leaving the terminal UI
- Create branches and worktrees without losing your current work
- Clean up commit history with visual rebase, squash, fixup, reword, and reorder actions
- Recover many branch/commit mistakes with lazygit undo (`z`) and redo (`Z`)

---

## Installation

Run the automated installer from this repository:

```zsh
chmod +x lazygit.zsh
./lazygit.zsh
```

The installer will:

1. **Check for Homebrew** and stop if Homebrew is missing
2. **Install or upgrade lazygit** via Homebrew
3. **Verify lazygit is in your** `PATH`
4. **Print the most useful starter shortcuts**

**Manual installation:**

```zsh
brew install lazygit
```

Verify:

```zsh
lazygit --version
```

Launch lazygit from inside any Git repository:

```zsh
lazygit
```

---

## Core Concepts

lazygit is organized around panels. Each panel has its own shortcuts, and the bottom bar shows the keys available for the focused panel.

```
Repository
├── Status panel
├── Files / Worktrees / Submodules panel
├── Branches / Remotes / Tags panel
├── Commits / Reflog panel
└── Stash panel
```

| Panel | What it is | Common actions |
|-------|------------|----------------|
| Status | Repo summary and recent repos | Update check, config, all-branch log |
| Files | Working tree and staged changes | Stage, unstage, discard, commit, stash |
| Worktrees | Linked working directories | Create, switch, remove worktrees |
| Branches | Local branches | New branch, checkout, merge, rebase, PR |
| Remotes | Remote repositories and branches | Fetch, checkout remote branch, set upstream |
| Commits | Current branch history | Rebase, squash, fixup, cherry-pick, tag |
| Stash | Saved work-in-progress entries | Apply, pop, drop, branch from stash |

**Key insight:** lazygit actions depend on focus. `n` means "new branch" in the branches panel, but "new worktree" in the worktrees panel. If a key is not doing what you expect, check which panel is focused.

---

## Navigation

### Moving around

| Action | Key |
|--------|-----|
| Move up / down | `k` / `j` or arrow keys |
| Move left / right between panels | `h` / `l` or arrow keys |
| Switch view within a panel | `tab` |
| Jump to panel 1-5 | `1` through `5` |
| Focus main view | `0` |
| Open selected item | `enter` |
| Return / close popup | `esc` |
| Search or filter current view | `/` |
| Help / all keybindings | `?` |
| Quit | `q` or `ctrl+c` |

### Panel jump mental model

The exact panel shown by `1` through `5` depends on your layout, but the default order is usually:

| Key | Area |
|-----|------|
| `1` | Status |
| `2` | Files / Worktrees / Submodules |
| `3` | Branches / Remotes / Tags |
| `4` | Commits / Reflog |
| `5` | Stash |

Use `[` and `]` to move between tabs inside a panel, for example from **Files** to **Worktrees** or from **Branches** to **Remotes**.

---

## Common Actions

These are the actions most developers repeat every day. The panel matters: move focus there first, then press the key.

| # | Action | Panel / Context | Keys | Git equivalent |
|---|--------|-----------------|------|----------------|
| 1 | Stage one file | Files | `space` | `git add <file>` |
| 2 | Stage all files | Files | `a` | `git add -A` |
| 3 | Stage one hunk | Files -> file | `enter`, `space` | `git add -p` |
| 4 | Stage selected lines | Staging view | `v`, move, `space` | `git add -p` with split/edit |
| 5 | Unstage file or hunk | Staged side / staging view | `space` or `d` | `git restore --staged ...` |
| 6 | Discard file change | Files | `d` | `git restore <file>` |
| 7 | Discard hunk or line | Staging view | `d` | `git restore -p <file>` |
| 8 | Commit staged changes | Files | `c` | `git commit -m ...` |
| 9 | Commit with editor | Files | `C` | `git commit` |
| 10 | Amend last commit | Files | `A` | `git commit --amend` |
| 11 | Push current branch | Global | `P` | `git push` |
| 12 | Push new branch and set upstream | Global | `P`, confirm upstream prompt | `git push -u origin <branch>` |
| 13 | Pull current branch | Global | `p` | `git pull` |
| 14 | Fetch remote changes | Files / Remotes | `f` | `git fetch` |
| 15 | Create new branch | Branches | `n` | `git checkout -b <branch>` |
| 16 | Checkout branch | Branches | `space` | `git checkout <branch>` |
| 17 | Checkout previous branch | Branches | `-` | `git checkout -` |
| 18 | Checkout by branch name | Branches | `c` | `git checkout <branch>` |
| 19 | Move accidental commits to new branch | Branches / Commits | `N` | create branch and move unpushed commits |
| 20 | Create worktree from branch | Branches | `w` | `git worktree add ... <branch>` |
| 21 | Create worktree from commit | Commits | `w` | `git worktree add ... <commit>` |
| 22 | Switch to worktree | Worktrees | `space` | change lazygit repo to worktree |
| 23 | Remove worktree | Worktrees | `d` | `git worktree remove ...` |
| 24 | Stash all changes | Files | `s` | `git stash push` |
| 25 | Choose stash type | Files | `S` | stash staged / unstaged / keep index variants |
| 26 | Apply stash | Stash | `space` | `git stash apply` |
| 27 | Pop stash | Stash | `g` | `git stash pop` |
| 28 | Drop stash | Stash | `d` | `git stash drop` |
| 29 | Start interactive rebase | Commits | `i` | `git rebase -i ...` |
| 30 | Edit commit history | Commits | `s` / `f` / `r` / `d` / `ctrl+j` / `ctrl+k` | squash / fixup / reword / drop / reorder |

**Tip:** Press `?` at any time to see the authoritative shortcuts for your installed lazygit version and config.

---

## Files, Hunks, and Lines

The Files panel is where most daily work starts.

### Stage a whole file

1. Focus the **Files** panel.
2. Move to the file with `j` / `k`.
3. Press `space`.

Result: the file moves from unstaged to staged.

Equivalent command:

```zsh
git add path/to/file
```

### Stage all files

Press `a` in the **Files** panel.

Result: all tracked and untracked changes are staged. If all files are already staged, `a` toggles them back.

Equivalent command:

```zsh
git add -A
```

### Stage only one hunk

1. Focus the **Files** panel.
2. Select the changed file.
3. Press `enter` to enter the staging view.
4. Move between hunks with `h` / `l` or left / right arrows.
5. Press `space` on the hunk you want.
6. Press `esc` to return to the Files panel.

Result: only that hunk is staged.

Equivalent command:

```zsh
git add -p path/to/file
```

### Stage selected lines

Use this when one hunk contains both changes you want and changes you do not want.

1. Focus the changed file and press `enter`.
2. Move to the first line you want.
3. Press `v` to start range selection.
4. Move with `j` / `k` until the right lines are selected.
5. Press `space` to stage the selected range.
6. Press `esc` to return.

**Tip:** In the staging view, `a` toggles hunk mode vs line-by-line selection mode.

### Unstage changes

If the main view is split between staged and unstaged changes:

| Action | Key |
|--------|-----|
| Switch staged / unstaged side | `tab` |
| Unstage selected staged hunk or line | `space` or `d` |
| Return to Files panel | `esc` |

### Discard changes

Discarding is destructive. Use it only when you really want to delete local work.

| Action | Key |
|--------|-----|
| Discard selected file | Files panel: `d` |
| Discard selected hunk or line | Staging view: `d` |
| Nuke the working tree | Files panel: `D`, then choose reset option |

---

## Commit and Push Actions

### Action: add a file, commit, push

Use this for the normal "I changed files and want to publish them" loop.

1. Focus **Files**.
2. Select each file and press `space`, or press `a` to stage all files.
3. Press `c`.
4. Type the commit message.
5. Press `enter` to commit.
6. Press `P` to push.

Equivalent commands:

```zsh
git add path/to/file
git commit -m "message"
git push
```

### Action: add one hunk, commit, push

Use this when a file contains multiple unrelated changes.

1. Focus **Files**.
2. Select the file.
3. Press `enter`.
4. Move to the hunk with `h` / `l`.
5. Press `space` to stage only that hunk.
6. Press `esc`.
7. Press `c`, write the commit message, then `enter`.
8. Press `P`.

Result: only the staged hunk is committed and pushed. Unstaged changes remain in your working tree.

### Action: add selected lines, commit, push

Use this when one hunk is still too large.

1. Focus **Files**.
2. Select the file and press `enter`.
3. Move to the first line.
4. Press `v`.
5. Move until the intended lines are selected.
6. Press `space`.
7. Press `esc`.
8. Press `c` and commit.
9. Press `P`.

### Action: commit with your editor

Use this when the commit message needs a body.

1. Stage the right files, hunks, or lines.
2. Press `C` in the Files panel.
3. Write the subject and body in your configured editor.
4. Save and close the editor.

Equivalent command:

```zsh
git commit
```

### Action: amend the last commit

Use this when you forgot a small change and have not pushed yet, or when your team allows force-pushing rewritten branch history.

1. Stage the additional change.
2. Press `A` in the Files panel.
3. Confirm the amend prompt.
4. If the original commit was already pushed, push with the force option only if your team allows it.

Equivalent command:

```zsh
git commit --amend
```

---

## Branches

Branches live in the **Branches** panel. Press `3` to jump there in the default layout, or move with `h` / `l`.

### Action: create a new branch, commit, push

1. Focus **Branches**.
2. Press `n`.
3. Enter a branch name, for example `feature/lazygit-guide`.
4. Press `enter` to create and check out the branch.
5. Focus **Files**.
6. Stage files with `space`, `a`, or hunk staging.
7. Press `c` and commit.
8. Press `P`.
9. If lazygit asks to set upstream, confirm.

Equivalent commands:

```zsh
git checkout -b feature/lazygit-guide
git add -A
git commit -m "add lazygit guide"
git push -u origin feature/lazygit-guide
```

### Action: checkout an existing branch

1. Focus **Branches**.
2. Select the branch.
3. Press `space`.

Equivalent command:

```zsh
git checkout branch-name
```

### Action: checkout by branch name

Use this when the branch list is long.

1. Focus **Branches**.
2. Press `c`.
3. Type the branch name.
4. Press `enter`.

Tip: enter `-` to switch to the previous branch.

### Action: create a branch from a selected commit

1. Focus **Commits**.
2. Select the commit.
3. Press `n`.
4. Enter the new branch name.
5. Confirm.

Equivalent command:

```zsh
git checkout -b new-branch <commit>
```

### Action: move commits made on the wrong branch to a new branch

Use this when you accidentally committed on `main` or on the wrong feature branch.

1. Focus **Branches** or **Commits**.
2. Press `N`.
3. Choose the option that matches where the new branch should start.
4. Enter the new branch name.
5. Confirm the operation.
6. Push with `P` if you want to publish the new branch.

Result: lazygit creates a new branch and moves the unpushed commits there.

### Action: merge a branch into the current branch

1. Check out the target branch first.
2. Focus **Branches**.
3. Select the source branch.
4. Press `M`.
5. Choose regular merge or squash merge.

Equivalent commands:

```zsh
git checkout target-branch
git merge source-branch
```

### Action: rebase current branch onto another branch

1. Focus **Branches**.
2. Select the branch you want to rebase onto, usually `main`.
3. Press `r`.
4. Confirm.

Equivalent command:

```zsh
git rebase main
```

---

## Worktrees

Git worktrees let one repository have multiple working directories checked out at the same time. This is useful when you need to review a PR, run a hotfix, or test another branch without stashing your current work.

### Mental model

```
repo/
├── .git
├── app code on feature/current
└── ../repo-hotfix/
    └── same repo, different branch, separate working tree
```

Each worktree has its own checked-out branch and files, but they share the same Git object database.

### Action: create a worktree from a branch

1. Focus **Branches**.
2. Select the branch.
3. Press `w`.
4. Choose or enter the worktree path.
5. Confirm.

Equivalent command:

```zsh
git worktree add ../repo-branch branch-name
```

### Action: create a worktree from a commit

1. Focus **Commits**.
2. Select the commit.
3. Press `w`.
4. Enter the worktree path and branch details when prompted.
5. Confirm.

Use this for testing an old commit or starting a branch from a specific point.

### Action: switch to a worktree

1. Focus the **Files / Worktrees / Submodules** panel.
2. Press `]` or `[` until the **Worktrees** tab is visible.
3. Select the worktree.
4. Press `space`.

Result: lazygit switches its UI to that worktree.

### Action: remove a worktree

1. Focus **Worktrees**.
2. Select the worktree.
3. Press `d`.
4. Confirm only if you no longer need that working directory.

Equivalent command:

```zsh
git worktree remove ../repo-branch
```

### Recommended worktree pattern

Keep sibling directories next to the main repo:

```zsh
~/code/my-app          # main working copy
~/code/my-app-hotfix   # worktree for urgent fixes
~/code/my-app-review   # worktree for reviewing a PR branch
```

This keeps tooling paths predictable and avoids hiding large working trees inside the repo.

---

## Stash

Use stash when you need to temporarily clear your working tree without committing.

### Action: stash all changes

1. Focus **Files**.
2. Press `s`.
3. Confirm.

Equivalent command:

```zsh
git stash push
```

### Action: choose stash type

Press `S` in the **Files** panel to open stash options.

Use this when you want to stash only staged changes, only unstaged changes, or use a less common stash variant.

### Action: apply, pop, or drop stash

Focus the **Stash** panel:

| Action | Key | Git equivalent |
|--------|-----|----------------|
| Apply stash and keep it | `space` | `git stash apply` |
| Apply stash and remove it | `g` | `git stash pop` |
| Delete stash | `d` | `git stash drop` |
| Create branch from stash | `n` | `git stash branch ...` |
| Create worktree from stash | `w` | worktree from stash base |

### Action: stash, switch branch, restore work

1. Focus **Files** and press `s`.
2. Focus **Branches**.
3. Select the target branch and press `space`.
4. Focus **Stash**.
5. Select the stash and press `g` to pop it.

Tip: if you do this often, consider a worktree instead so your current branch can stay dirty while you work elsewhere.

---

## History Cleanup

The **Commits** panel is where lazygit is strongest. It makes interactive rebase operations visible and keyboard-driven.

### Action: clean up commits before opening a PR

1. Focus **Commits**.
2. Press `i` to start an interactive rebase.
3. Use the commit actions below.
4. Press `m` to open merge/rebase options.
5. Choose continue when ready.

| Action | Key | Meaning |
|--------|-----|---------|
| Squash into commit below | `s` | Combine commits and keep/edit messages |
| Fixup into commit below | `f` | Combine commits and discard selected message |
| Reword commit | `r` | Change commit message |
| Drop commit | `d` | Remove commit |
| Move commit down | `ctrl+j` | Reorder commit later in the todo list |
| Move commit up | `ctrl+k` | Reorder commit earlier in the todo list |
| Mark commit as pick | `p` | Keep commit during rebase |

### Action: create a fixup commit for an older commit

Use this during review when you want reviewers to see the follow-up change, then autosquash later.

1. Stage the fixup change.
2. Focus **Commits**.
3. Select the commit the change belongs to.
4. Press `F`.
5. Choose the fixup or amend option.

Later, select the first commit in the branch and press `S` to autosquash fixup commits.

### Action: find the base commit for a fixup

1. Stage the related changes.
2. Focus **Files**.
3. Press `ctrl+f`.
4. lazygit selects the likely commit in the Commits panel.
5. Press `F` to create a fixup commit, or `A` to amend into that commit if rewriting is safe.

### Action: cherry-pick a commit

1. Focus **Commits**.
2. Select the commit to copy.
3. Press `C`.
4. Check out the target branch.
5. Focus **Commits**.
6. Press `V` to paste/cherry-pick.

Equivalent command:

```zsh
git cherry-pick <commit>
```

### Action: undo or redo a branch/commit operation

| Action | Key |
|--------|-----|
| Undo last supported Git operation | `z` |
| Redo | `Z` |

Undo uses Git reflog-based recovery. It helps with many commit and branch operations, but it does not restore discarded working tree changes.

---

## Pull Requests

lazygit can create or open pull requests from the Branches panel when your Git provider is supported and the relevant CLI/auth setup is available.

### Action: create a pull request

1. Push your branch with `P`.
2. Focus **Branches**.
3. Select the current branch.
4. Press `o` to create a pull request.
5. Use `O` for pull-request creation options.

### Action: open pull request in browser

1. Focus **Branches** or **Commits**.
2. Select the branch or commit with PR metadata.
3. Press `G`.

If GitHub PR metadata does not appear, verify the GitHub CLI is installed and authenticated:

```zsh
gh auth status
```

---

## Quick Reference

### Universal

| Action | Key |
|--------|-----|
| Help / keybindings | `?` |
| Quit | `q` / `ctrl+c` |
| Cancel / return | `esc` |
| Search / filter | `/` |
| Move item | `j` / `k` or arrows |
| Move panel | `h` / `l` or arrows |
| Jump panel | `1`-`5` |
| Focus main view | `0` |
| Push | `P` |
| Pull | `p` |
| Refresh | `R` |
| Undo / redo | `z` / `Z` |
| Execute shell command | `:` |
| Toggle whitespace in diff | `ctrl+w` |
| Increase / decrease diff context | `}` / `{` |

### Files

| Action | Key |
|--------|-----|
| Stage selected file | `space` |
| Stage all files | `a` |
| Enter staging view | `enter` |
| Commit | `c` |
| Commit with editor | `C` |
| Commit without hooks | `w` |
| Amend last commit | `A` |
| Stash all | `s` |
| Stash options | `S` |
| Discard selected file | `d` |
| Reset options | `D` |
| Fetch | `f` |
| Edit file | `e` |
| Open file | `o` |
| Toggle file tree | `` ` `` |

### Staging View

| Action | Key |
|--------|-----|
| Previous / next hunk | `h` / `l` |
| Toggle hunk vs line mode | `a` |
| Select range | `v` |
| Stage / unstage selection | `space` |
| Discard selection | `d` |
| Switch staged / unstaged view | `tab` |
| Edit hunk | `E` |
| Return to Files panel | `esc` |

### Branches

| Action | Key |
|--------|-----|
| New branch | `n` |
| Checkout selected branch | `space` |
| Checkout by name | `c` |
| Checkout previous branch | `-` |
| Move commits to new branch | `N` |
| New worktree | `w` |
| Rebase current branch onto selected | `r` |
| Merge selected into current | `M` |
| Fast-forward selected branch | `f` |
| Rename branch | `R` |
| Delete branch | `d` |
| Upstream options | `u` |
| Create PR | `o` |
| PR options | `O` |
| Open PR in browser | `G` |

### Commits

| Action | Key |
|--------|-----|
| Start interactive rebase | `i` |
| Squash down | `s` |
| Fixup down | `f` |
| Reword | `r` |
| Drop | `d` |
| Edit commit | `e` |
| Move commit down / up | `ctrl+j` / `ctrl+k` |
| Amend selected commit with staged changes | `A` |
| Create fixup commit | `F` |
| Autosquash fixup commits | `S` |
| Cherry-pick copy | `C` |
| Cherry-pick paste | `V` |
| Revert commit | `t` |
| Tag commit | `T` |
| Create branch from commit | `n` |
| New worktree from commit | `w` |
| Reset options | `g` |

### Worktrees

| Action | Key |
|--------|-----|
| New worktree | `n` |
| Switch to selected worktree | `space` |
| Open in editor | `o` |
| Remove worktree | `d` |
| Filter worktrees | `/` |

### Stash

| Action | Key |
|--------|-----|
| Apply stash | `space` |
| Pop stash | `g` |
| Drop stash | `d` |
| New branch from stash | `n` |
| New worktree from stash | `w` |
| Rename stash | `r` |

---

## Troubleshooting

### A shortcut does something different than expected

lazygit shortcuts are context-sensitive. Check the focused panel, then press `?` to see the keybindings for that context.

### I cannot find the Worktrees tab

Worktrees share the same side panel as Files and Submodules in the default layout. Focus that panel, then press `[` or `]` until **Worktrees** is selected.

### Push asks about upstream

This is normal for a new branch. Confirm the prompt to set upstream.

Equivalent command:

```zsh
git push -u origin branch-name
```

### I staged too much

Enter the file with `enter`, switch to the staged side with `tab` if needed, then press `space` or `d` on the staged hunk or line to unstage it.

### I discarded a change by mistake

Discarded working tree changes are not reliably recoverable with lazygit undo. Check your editor local history, Time Machine, or any generated backups. lazygit `z` is mainly for commit/branch operations, not deleted working tree content.

### A rebase or merge is in progress

Press `m` to open merge/rebase options. Choose continue, abort, or skip depending on the state.

If there are conflicts:

1. Focus **Files**.
2. Resolve files in your editor with `e`, or use merge conflict options with `M`.
3. Stage resolved files with `space`.
4. Press `m` and continue.

### The lazygit UI looks stale

Press `R` to refresh lazygit state. This reruns status/branch/log checks. Use `f` when you specifically want to fetch remote changes.

### Editor shortcuts do not work

Set your editor in lazygit config or Git config. On macOS, lazygit config is usually:

```zsh
~/Library/Application\ Support/lazygit/config.yml
```

Example:

```yaml
os:
  editPreset: 'vscode'
```

### Mouse selection is difficult

lazygit captures mouse events by default. On macOS terminals, hold Option while selecting text, or disable mouse events in lazygit config:

```yaml
gui:
  mouseEvents: false
```
