# Superpowers Skills Guide

A step-by-step walkthrough of `skills/superpowers.zsh`: what it installs, how the interactive prompts work, and what each phase of the script actually does.

---

## Table of Contents

1. [What is Superpowers?](#what-is-superpowers)
2. [Installation](#installation)
3. [Core Concepts](#core-concepts)
4. [The Installation Workflow](#the-installation-workflow)
5. [Updating Skills](#updating-skills)
6. [Quick Reference](#quick-reference)
7. [Troubleshooting](#troubleshooting)

---

## What is Superpowers?

[**Superpowers**](https://github.com/obra/superpowers) is a collection of reusable skills for AI coding CLIs — brainstorming, TDD, systematic debugging, writing plans, git worktrees, and more. Each skill is a folder containing a `SKILL.md` (plus any supporting assets) that a CLI can load and invoke by name.

`skills/superpowers.zsh` doesn't write these skills itself — it clones the upstream repo and copies its `skills/*` folders into whichever CLI(s) you choose: Claude Code, Codex, and/or OpenCode.

---

## Installation

Run the script directly from the repo:

```zsh
chmod +x skills/superpowers.zsh
./skills/superpowers.zsh
```

The script is interactive — it asks which CLI(s) to install for — and safe to rerun. It never overwrites a skill folder that's already present, so running it again only fills in whatever is missing.

---

## Core Concepts

| Concept | What it means |
|---|---|
| Target CLIs | Claude Code (`~/.claude/skills`), Codex (`~/.codex/skills`), and OpenCode (no local directory — manual step, see below) |
| Idempotent copy | `copy_skills` skips any skill folder that already exists at the destination. It never merges or overwrites — to pick up an update, delete the folder first |
| Temp clone | The Superpowers repo is cloned once into a `mktemp -d` temp directory and always removed at the end, whether the install succeeded or not |
| Detection-gated | The script only prompts about CLIs it actually finds on your `PATH` (`command -v claude/codex/opencode`) |

**Key insight:** the script treats "install" as "copy any skill folder that's missing." It has no update or overwrite mode — deleting the local folder is how you opt into picking up a newer version.

---

## The Installation Workflow

The script runs these phases in order every time. They correspond to the numbered `=== N. ... ===` comments inside `skills/superpowers.zsh`.

### 1. Detect supported CLIs

The script checks `command -v` for `claude`, `codex`, and `opencode` and builds a list of what it finds, printing a ✅/⚠️ line for each.

```zsh
for cli in claude codex opencode; do
  command -v "$cli" >/dev/null 2>&1
done
```

If none of the three are installed, the script prints an error and exits immediately — there's nothing to install skills into.

### 2. Choose which CLI(s) to install for

For each detected CLI, the script prints a numbered menu entry plus an `a) all detected` option, then reads your input:

```
❓ Which CLI(s) do you want to install Superpowers for?
   1) claude
   2) codex
   a) all detected
👉 Enter your choice (e.g. '1', '1 2', or 'a'):
```

- `a` selects everything detected.
- A space-separated list of numbers (e.g. `1 2`) selects specific CLIs.
- Any invalid token (out of range, non-numeric) re-prompts — the loop only exits once every token is valid.

### 3. Clone the Superpowers repository

This step only runs **if Claude and/or Codex were selected** — OpenCode's install path doesn't need the source files locally, since it's just a printed prompt.

```zsh
git clone --depth 1 --quiet "$SUPERPOWERS_REPO" "$TMP_DIR/superpowers"
```

The script requires `git` on `PATH` (exits with an error if missing) and reports how many skill folders were found in the clone, e.g. `Repository cloned (12 skills available).`

### 4. Copy skills into Claude Code and/or Codex

For each selected CLI, `copy_skills` walks every folder under `$SRC_DIR/skills/*` and, for each one:

- If a folder with that name already exists at the destination (`~/.claude/skills` or `~/.codex/skills`), it's skipped (`⏭️ ... already present, skipped`).
- Otherwise it's copied in full (`✅ ...`).

At the end it prints a one-line summary: `Claude Code: 9 copied, 3 already present → ~/.claude/skills`.

### 5. OpenCode path (manual)

OpenCode has no headless install, so the script just prints instructions instead of copying anything:

- Paste a prompt into an OpenCode session telling it to fetch and follow `INSTALL.md` from the Superpowers repo, **or**
- Add `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]` to `opencode.json`.

Either way, you restart OpenCode afterward and confirm by asking it about its superpowers.

### 6. Verify installations

`verify_skills` re-counts the skill folders in the clone and checks that each one has a `SKILL.md` at the destination:

```
✅ Claude Code: 12/12 Superpowers skills present in ~/.claude/skills
```

If any are missing, it prints a ⚠️ warning with the actual count and sets an internal failure flag (`overall_ok=false`). OpenCode is skipped here too — it's flagged as a manual verification step ("ask it inside OpenCode after following the prompt above").

### 7. Cleanup and wrap-up

The temp directory holding the clone is always removed (`rm -rf "$TMP_DIR"`), regardless of success. The script then exits non-zero if `overall_ok` was ever set to `false` during copy or verify; otherwise it prints next steps:

- Restart your CLI sessions to pick up the new skills.
- Verify by asking: *"Tell me about your superpowers."*
- To update later: delete the skill folder(s) you want refreshed and rerun the script.

---

## Updating Skills

### Action: pick up a newer version of a skill

The script never overwrites an existing skill folder, so "update" means removing the old copy first.

1. Delete the specific skill folder:
   ```zsh
   rm -rf ~/.claude/skills/<skill-name>
   ```
2. Rerun the installer:
   ```zsh
   ./skills/superpowers.zsh
   ```
3. Select the same CLI again — the now-missing folder gets copied fresh from a new clone.

To refresh everything, remove all skill folders under `~/.claude/skills` (or `~/.codex/skills`) and rerun instead of deleting one at a time.

---

## Quick Reference

| Phase | Trigger | Result |
|---|---|---|
| Detect CLIs | Always runs first | Builds the list of installable targets from `PATH` |
| Choose CLI(s) | Always, after detection | Determines which of Claude/Codex/OpenCode get installed |
| Clone repo | Claude and/or Codex selected | Temp checkout of the Superpowers repo |
| Copy skills | Claude and/or Codex selected | New skill folders land in `~/.claude/skills` and/or `~/.codex/skills`; existing ones are left alone |
| OpenCode instructions | OpenCode selected | Prompt/plugin-entry printed — no files copied |
| Verify | Claude and/or Codex selected | Reports `present/total` `SKILL.md` count per CLI |
| Cleanup | Always runs last | Temp clone removed; exits non-zero if anything failed |

---

## Troubleshooting

### "None of the supported CLIs are installed"

The script found no `claude`, `codex`, or `opencode` binary on `PATH`. Install one of them first (e.g. run `opencode.zsh`), then rerun `superpowers.zsh`.

### "git is not installed"

Cloning the Superpowers repo requires `git`. Install the Xcode Command Line Tools (`xcode-select --install`) or `brew install git`, then rerun.

### The clone fails

Usually a network issue or an unreachable `$SUPERPOWERS_REPO` URL. The script cleans up its temp directory and exits — just rerun once connectivity is restored.

### Verification shows "only N/M skills found"

This means at least one skill folder is missing `SKILL.md`, either because a copy was interrupted or a folder was partially deleted. Remove the incomplete folder(s) and rerun the script so they get copied fresh:

```zsh
rm -rf ~/.claude/skills/<incomplete-skill>
./skills/superpowers.zsh
```

### OpenCode doesn't show any new skills

This is expected — OpenCode has no headless install path. You must paste the printed prompt (or add the `opencode.json` plugin entry) inside an OpenCode session yourself, then restart OpenCode.

### Rerunning the script does nothing

If every skill folder already exists at the destination, `copy_skills` will skip all of them — this is correct idempotent behavior, not a bug. To force specific skills to be recopied, delete their folders first (see [Updating Skills](#updating-skills)).
