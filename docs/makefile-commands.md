# Makefile Commands Reference

Full reference for every target in this repo's `Makefile`. Run `make help` for the quick version.

All `-sync` targets back up whatever is currently installed (moving or copying it to a timestamped backup) before copying the repo's config into place. The repo is always the source of truth.

---

## Table of Contents

1. [Default](#default)
2. [Doom Emacs](#doom-emacs)
3. [tmux](#tmux)
4. [Herdr](#herdr)
5. [OpenCode](#opencode)
6. [Claude Skills & Settings](#claude-skills--settings)
7. [Skills Wipe](#skills-wipe)
8. [Combined](#combined)
9. [Shortcuts](#shortcuts)
10. [Testing](#testing)
11. [Shell](#shell)
12. [Help](#help)

---

## Default

| Command | What it does |
|---|---|
| `make` / `make all` | Sync Doom Emacs config: back up existing `~/.doom.d`, copy the repo's `.doom.d`, run `doom sync` |

---

## Doom Emacs

| Command | What it does |
|---|---|
| `make doom-sync` | Back up existing config, then copy `.doom.d` from the repo to `~/.doom.d` and run `doom sync` |
| `make doom-backup` | Move existing `~/.doom.d` to a timestamped backup (`~/.doom.d_backup_YYYY_MM_DD_HH_MM`) |
| `make doom-restore` | Restore the most recent backup by moving it back to `~/.doom.d` (deletes the current config first) |
| `make doom-diff` | Diff `config.el`, `init.el`, and `packages.el` between installed `~/.doom.d` and the repo copy |
| `make clean-backup-doom` | Delete all `~/.doom.d_backup_*` backups (current `~/.doom.d` becomes source of truth) |

---

## tmux

| Command | What it does |
|---|---|
| `make tmux-sync` | Back up existing config, copy `tmux.conf` from the repo to `~/.tmux.conf`, and reload if inside a tmux session |
| `make tmux-backup` | Copy existing `~/.tmux.conf` to a timestamped backup (`~/.tmux.conf.backup_YYYY_MM_DD_HH_MM`) |
| `make tmux-restore` | Restore the most recent tmux backup (reloads config if inside a tmux session) |
| `make tmux-diff` | Diff installed `~/.tmux.conf` vs the repo copy |
| `make clean-backup-tmux` | Delete all `~/.tmux.conf.backup_*` backups (current `~/.tmux.conf` becomes source of truth) |

---

## Herdr

| Command | What it does |
|---|---|
| `make herdr-sync` | Back up existing `~/.config/herdr/config.toml`, then copy repo Herdr keybinding additions/scripts and reload the server |
| `make herdr-backup` | Copy existing Herdr config to a timestamped backup (`~/.config/herdr/config.toml.backup_YYYY_MM_DD_HH_MM`) |
| `make herdr-restore` | Restore the most recent Herdr config backup (reloads config when `herdr` is installed) |
| `make herdr-diff` | Diff installed vs repo Herdr keybinding config |
| `make clean-backup-herdr` | Delete all Herdr config backups (current config becomes source of truth) |

---

## OpenCode

| Command | What it does |
|---|---|
| `make opencode-sync` | Back up existing OpenCode config and commands, then copy the repo config to `~/.config/opencode` |
| `make opencode-backup` | Back up `opencode.jsonc` and move existing commands to a timestamped `commands_backup_*` |
| `make opencode-restore` | Restore the most recent config and commands backup (deletes current commands first) |
| `make opencode-diff` | Diff installed vs repo OpenCode config and commands |
| `make clean-backup-opencode` | Delete all OpenCode config and command backups (current config/commands become source of truth) |

---

## Claude Skills & Settings

| Command | What it does |
|---|---|
| `make claude-sync` | Back up existing `~/.claude/skills` and `settings.json`, then copy repo skills and settings there. Moves the entire skills dir, so all skills must live in the repo (`commit`, `pr-gh`, `graphify`, `guide`, `create-skill`) to survive sync |
| `make claude-backup` | Move existing skills to a timestamped backup (`~/.claude/skills_backup_YYYY_MM_DD_HH_MM`) and copy `settings.json` to a timestamped backup |
| `make claude-restore` | Restore the most recent skills backup (deletes current skills first) plus the most recent `settings.json` backup |
| `make claude-diff` | Diff installed vs repo Claude skills (recursive) and `settings.json` |
| `make clean-backup-claude` | Delete all Claude skill and settings backups (current `~/.claude` becomes source of truth) |

---

## Skills Wipe

`make skills-wipe` runs `skills/wipe-skills.zsh` and passes `$(ARGS)` straight through. This **permanently deletes** installed AI coding skills for Claude Code, Codex, and/or OpenCode. See [docs/guide_superpowers.md](guide_superpowers.md#wiping-skills) for the full walkthrough.

| Command | What it does |
|---|---|
| `make skills-wipe` | Wipe installed skills (interactive by default) |
| `make wipe` | Alias for `skills-wipe` |

Pass flags via `ARGS`:

```sh
make skills-wipe ARGS="--all --no-graphify"
make skills-wipe ARGS="--claude --codex --no-superpowers --force"
make wipe ARGS="--opencode"
```

### `skills/wipe-skills.zsh` flags

| Flag | Effect |
|---|---|
| `--claude` / `--codex` / `--opencode` | Scope the wipe to that CLI only (repeatable) |
| `--all` | Wipe every detected skill for every detected CLI |
| `--no-<skill>` | Keep a skill by name, e.g. `--no-graphify` |
| `--no-superpowers` | Keep the whole Superpowers bundle, including the OpenCode plugin line |
| `--force` | Skip the final confirmation prompt |
| `-h`, `--help` | Print usage |

**Interactivity rule:** with no scope flags, the script shows a numbered menu. With `--claude`/`--codex`/`--opencode`/`--all` it deletes everything matched after a single confirmation (unless `--force`).

**Safety:** deletion is confined to detected skill dirs under `~/.claude/skills/*`, `~/.codex/skills/*`, and `~/.cache/opencode/packages/superpowers@*`; skill names with `/`, `..`, or a leading `.` are rejected; paths are resolved and checked against their base before any `rm -rf`. `opencode.jsonc` is backed up before the Superpowers plugin line is stripped, and the script refuses to write an empty `opencode.jsonc`.

**Restore:** `make csync` re-syncs repo skills to `~/.claude/skills`; `./skills/superpowers.zsh` reinstalls the Superpowers bundle; for OpenCode, re-add the `superpowers@git` plugin line to `opencode.jsonc` (backup at `~/.config/opencode/opencode.jsonc.backup_*`) and restart.

---

## Combined

| Command | What it does |
|---|---|
| `make skills-sync` | Run `opencode-sync` + `claude-sync` in one go |
| `make clean-backup-skills` | Delete OpenCode + Claude skill backups |
| `make clean-backup-all` | Delete all known config backups |

---

## Shortcuts

| Command | Alias for |
|---|---|
| `make sync` | `doom-sync` |
| `make backup` | `doom-backup` |
| `make restore` | `doom-restore` |
| `make diff` | `doom-diff` |
| `make tsync` | `tmux-sync` |
| `make tbackup` | `tmux-backup` |
| `make trestore` | `tmux-restore` |
| `make tdiff` | `tmux-diff` |
| `make hsync` | `herdr-sync` |
| `make hbackup` | `herdr-backup` |
| `make hrestore` | `herdr-restore` |
| `make hdiff` | `herdr-diff` |
| `make osync` | `opencode-sync` |
| `make obackup` | `opencode-backup` |
| `make orestore` | `opencode-restore` |
| `make odiff` | `opencode-diff` |
| `make csync` | `claude-sync` |
| `make cbackup` | `claude-backup` |
| `make crestore` | `claude-restore` |
| `make cdiff` | `claude-diff` |
| `make ssync` | `skills-sync` |
| `make wipe` | `skills-wipe` |

---

## Testing

| Command | What it does |
|---|---|
| `make soft-test` | Validate all `.zsh` scripts in the repo: shebang lines, Zsh syntax, file permissions, script structure (Purpose, Author, echo), and Doom/tmux config file presence |

---

## Shell

| Command | What it does |
|---|---|
| `make reload-shell` | Reload the shell (restart with `.zshrc`) |

---

## Help

| Command | What it does |
|---|---|
| `make help` | Show this reference in the terminal |
