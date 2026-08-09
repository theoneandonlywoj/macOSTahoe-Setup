# Herdr Keyboard Shortcuts Guide

A complete keyboard reference for Herdr (terminal agent multiplexer, [herdr.dev](https://herdr.dev)) — from the prefix key to copy mode, custom bindings, and prefix-free chords. Written against Herdr **0.8.0**.

---

## Table of Contents

1. [What is Herdr?](#what-is-herdr)
2. [Installation](#installation)
3. [Core Concepts](#core-concepts)
4. [The Prefix Key](#the-prefix-key)
5. [Getting Help In-App](#getting-help-in-app)
6. [Panes](#panes)
7. [Tabs](#tabs)
8. [Workspaces & Worktrees](#workspaces--worktrees)
9. [Navigate Mode (Goto)](#navigate-mode-goto)
10. [Copy Mode & Scrollback](#copy-mode--scrollback)
11. [Agents, Notifications & Session Control](#agents-notifications--session-control)
12. [Customizing Keybindings](#customizing-keybindings)
13. [Quick Reference](#quick-reference)
14. [Troubleshooting](#troubleshooting)
15. [Next Steps](#next-steps)

---

## What is Herdr?

**Herdr** is a terminal agent multiplexer. It organizes shells and coding-agent CLIs into persistent workspaces with panes, tabs, keyboard shortcuts, mouse controls, notifications, and git worktree support.

Think of it as tmux-style terminal layout management built for running multiple coding agents side by side.

**Why you need it:**

- Run OpenCode, Claude Code, Codex, shells, git tools, and status panes in one workspace
- Keep agent sessions organized by project, tab, and pane
- Jump to agents that need attention from notifications or sidebar shortcuts
- Create isolated git worktrees so agents can work in parallel
- Use either keyboard shortcuts or mouse controls for every core layout action

---

## Installation

Run the automated installer from this repository:

```zsh
chmod +x herdr.zsh
./herdr.zsh
```

The installer will:

1. **Install Herdr** via Homebrew
2. **Seed** `~/.config/herdr/config.toml`
3. **Offer integrations** for detected coding-agent CLIs such as Claude Code, Codex, Cursor, and OpenCode
4. **Prompt for optional developer plugins**
5. **Add project-specific helper bindings**, including the 4-tab command workspace shortcut described later

Start Herdr:

```zsh
herdr
```

Or run the server in the background:

```zsh
brew services start herdr
```

**Keyboard is optional.** Herdr is fully mouse-drivable — click panes, drag borders, split and switch from right-click menus. This guide is for when you want to keep your hands on the keyboard.

---

## Core Concepts

Herdr organizes work in three levels, like tmux:

| Level     | What it is                             | Analogy             |
|-----------|----------------------------------------|---------------------|
| Workspace | A project (has its own working dir)    | A tmux session      |
| Tab       | A screen inside a workspace            | A tmux window       |
| Pane      | An individual terminal (or agent)      | A tmux pane         |

Keyboard interaction happens in **modes**. You are normally typing into your terminal; the prefix key opens a window where the *next* keypress goes to Herdr instead:

```mermaid
stateDiagram-v2
    [*] --> Terminal
    Terminal --> PrefixMode: ctrl+b
    PrefixMode --> Terminal: action key (v, c, n, ...)
    PrefixMode --> NavigateMode: g (goto)
    PrefixMode --> ResizeMode: r
    PrefixMode --> CopyMode: [
    NavigateMode --> Terminal: enter / esc
    ResizeMode --> Terminal: esc
    CopyMode --> Terminal: q / esc
```

---

## The Prefix Key

Every Herdr action starts with the **prefix**: press `ctrl+b`, release, then press the action key. `prefix+v` below always means "press `ctrl+b`, then `v`".

Change the prefix in `~/.config/herdr/config.toml`:

```toml
[keys]
prefix = "ctrl+b"   # examples: "ctrl+a", "f12", "esc", "-"
```

Apply it without restarting:

```zsh
herdr server reload-config
```

You can also reload from inside Herdr with `prefix+shift+r`.

### Verify

Press `prefix+?` — the keybinding help overlay should open and show your prefix on every binding.

---

## Getting Help In-App

| Action                                | Keys        |
|---------------------------------------|-------------|
| Show all active keybindings (overlay) | `prefix+?`  |
| Filter the list                       | `/`         |
| Clear the filter                      | `ctrl+u`    |
| Open settings                         | `prefix+s`  |

`prefix+?` is the authoritative list for *your* config — when in doubt, trust it over any document (including this one).

---

## Panes

Panes are where your shells and agents live. Splits, movement, and lifecycle:

| Action                    | Keys                      |
|---------------------------|---------------------------|
| Split right (vertical)    | `prefix+v`                |
| Split down (horizontal)   | `prefix+minus` (`-`)      |
| Focus pane left/down/up/right | `prefix+h` / `j` / `k` / `l` |
| Cycle to next pane        | `prefix+tab`              |
| Cycle to previous pane    | `prefix+shift+tab`        |
| Swap pane left/down/up/right | `prefix+shift+h` / `j` / `k` / `l` |
| Zoom (fullscreen) focused pane | `prefix+z`           |
| Close pane                | `prefix+x`                |
| Rename pane               | `prefix+shift+p`          |
| Enter resize mode         | `prefix+r`                |

Notes:

- **Zoom** toggles: `prefix+z` again restores the layout.
- **Resize mode** (`prefix+r`) is modal — adjust the focused pane's borders, then leave the mode. Its inner keys are listed in the `prefix+?` overlay.
- `last_pane` (jump back and forth between two panes) exists but is **unbound by default**; see [Customizing Keybindings](#customizing-keybindings).

### Verify

`prefix+v` then `prefix+minus` should give you three panes; `prefix+h/j/k/l` moves the focus ring between them; `prefix+z` makes one fill the tab.

---

## Tabs

Tabs group panes inside a workspace:

| Action              | Keys               |
|---------------------|--------------------|
| New tab             | `prefix+c`         |
| Next tab            | `prefix+n`         |
| Previous tab        | `prefix+p`         |
| Jump to tab 1–9     | `prefix+1..9`      |
| Rename tab          | `prefix+shift+t`   |
| Close tab           | `prefix+shift+x`   |

---

## Workspaces & Worktrees

Workspaces are top-level projects; each has its own working directory. Herdr can also create **git worktrees** so agents work on isolated copies of a repo:

| Action                          | Keys               |
|---------------------------------|--------------------|
| Workspace picker                | `prefix+w`         |
| Goto picker (navigate mode)     | `prefix+g`         |
| New workspace                   | `prefix+shift+n`   |
| New git worktree                | `prefix+shift+g`   |
| Rename workspace                | `prefix+shift+w`   |
| Close workspace                 | `prefix+ctrl+x`    |
| Toggle sidebar                  | `prefix+b`         |

Unbound by default (available to map yourself): `previous_workspace`, `next_workspace`, `switch_workspace` (indexed `prefix+1..9` style), `open_worktree`, `remove_worktree`.

To close the current workspace, press `prefix+ctrl+x`, then confirm the prompt if `confirm_close` is enabled. This closes the workspace and its panes; use `prefix+x` for only the focused pane, `prefix+shift+x` for only the current tab, and `prefix+q` when you only want to detach from Herdr while keeping the session running.

---

## Navigate Mode (Goto)

`prefix+g` opens the goto picker — a modal navigate mode for jumping anywhere with plain keys (no prefix needed while it is open):

| Action                       | Keys (inside navigate mode) |
|------------------------------|------------------------------|
| Move up/down the workspace list | `up` / `down` (or `k` / `j` via config) |
| Focus pane left/down/up/right   | `h` / `j` / `k` / `l`     |
| Focus pane left/right (always)  | `left` / `right` arrows   |
| Confirm / leave                 | `enter` / `esc`           |

Navigate-mode keys are configured separately from the `prefix+` bindings (`navigate_*` options) and win over terminal input only while the picker is open. They must be plain keys — `prefix+`, `esc`, `enter`, `tab`, and unmodified `1..9` cannot be remapped here.

---

## Copy Mode & Scrollback

Enter copy mode with `prefix+[` to scroll, search, and copy with the keyboard (vim-style):

| Action                    | Keys                                   |
|---------------------------|----------------------------------------|
| Move                      | `h` / `j` / `k` / `l`                  |
| Word forward / back / end | `w` / `b` / `e`                        |
| Paragraph up / down       | `{` / `}`                              |
| Page up / down            | `PageUp` / `PageDown`, `ctrl+b` / `ctrl+f` |
| Half-page up / down       | `ctrl+u` / `ctrl+d`                    |
| Search forward / backward | `/` / `?`                              |
| Next / previous match     | `n` / `N`                              |
| Start selection           | `v` or `Space`                         |
| Copy selection            | `y` or `Enter`                         |
| Exit copy mode            | `q` or `Esc`                           |

Related:

| Action                                   | Keys        |
|-------------------------------------------|-------------|
| Edit scrollback (open history in editor)  | `prefix+e`  |
| Paste image into a remote session         | `ctrl+v` (only in `herdr --remote`) |

---

## Agents, Notifications & Session Control

Herdr auto-detects coding agents (Claude Code, Codex, OpenCode, ...) running in panes and tracks their state (idle / working / blocked / done):

| Action                                    | Keys               |
|--------------------------------------------|--------------------|
| Open the pane that raised a notification   | `prefix+o`         |
| Previous / next agent in sidebar           | `prefix+shift+up` / `prefix+shift+down` |
| Jump to agent 1-9                          | `prefix+ctrl+1..9` |
| Create 4-tab command workspace             | `prefix+ctrl+w`    |
| Detach from the session (keeps running)    | `prefix+q`         |
| Reload config                              | `prefix+shift+r`   |
| Open settings                              | `prefix+s`         |

Agent navigation is unbound by Herdr defaults, but this setup maps `previous_agent`, `next_agent`, and indexed `focus_agent` with prefix-only shortcuts so they do not collide with agent TUIs such as OpenCode. `focus_agent` only accepts the literal `1..9` range — Herdr does not support narrowing it to fewer slots. `open_notification_target` is pinned explicitly to `prefix+o` as well, even though it matches Herdr's own default — Herdr has no setting that focuses a pane automatically when a notification fires, so this manual follow-up keypress is the closest available equivalent to "auto-focus on notification."

There is no separate `agent_picker` action like `workspace_picker` (`prefix+w`) in Herdr 0.7/0.8. For picker-style navigation, use `prefix+g` to open the session navigator, then move through workspaces and panes. For agent-specific movement, use `prefix+shift+up` / `prefix+shift+down` to step through agents in the sidebar, `prefix+ctrl+1..9` to jump directly to agent N, or `prefix+o` when a notification points at an agent that needs attention.

Each sidebar agent row shows its work status explicitly via `[ui.sidebar.agents]`, plus a native notification when something changes in the background. `agent_panel_sort = "spaces"` keeps agents grouped by workspace, in the same order as the spaces themselves, rather than sorting by priority — so agents don't shuffle position as their state changes:

```toml
[ui]
agent_panel_sort = "spaces"                     # group by workspace, in space order; no reshuffling on state change
show_agent_labels_on_pane_borders = true        # label each pane border with its detected agent kind

[ui.sidebar.agents]
rows = [["state_icon", "state_text", "workspace", "tab"], ["terminal_title_stripped"], ["agent"]]

[ui.sidebar.spaces]
rows = [["state_icon", "workspace"], ["branch", "git_status"]]  # mirror agent rows with per-workspace git state

[ui.toast]
delivery = "system"             # macOS notification when a background agent finishes or needs input
```

`state_icon` and `state_text` together spell out idle/working/blocked/done per agent instead of relying on the icon alone. `terminal_title_stripped` adds a 3rd row with the agent's live task/tool context, since most agent CLIs set their terminal title to reflect what they're currently doing. `rows` only nests two levels deep — each top-level entry is one stacked visual row of tokens, but a row's own elements cannot themselves be arrays (Herdr rejects that as an invalid sidebar token).

`[ui.sidebar.spaces]` applies the same idea to workspaces: branch and dirty/clean git status show alongside each workspace's icon, so project state sits right next to agent state. `show_agent_labels_on_pane_borders` complements both by putting the agent kind directly on the pane border — useful once several agents are split across panes in one tab and you want to tell them apart without opening the sidebar.

The first `system`-delivered notification may prompt macOS to grant your terminal app notification permission — allow it in System Settings → Notifications, or switch `delivery` to `"herdr"` for an in-app-only toast instead.

This setup also adds `prefix+ctrl+w`, which runs `~/.config/herdr/scripts/new-workspace-4-tabs.zsh`. It greets you using your Git user name, creates a new workspace with four tabs: `agent-high` (auto-accepting edits with the most capable, high-thinking model), `git` (a plain shell), `shell` (a plain shell), and `agent-low` (auto-accepting edits with a small-task model for commit messages and PR descriptions).

The agent tabs launch the first harness from `HERDR_4TAB_HARNESS_ORDER` that is installed. By default that order is `claude codex opencode`, so Claude Code is preferred, then Codex, then OpenCode. The launch command for each harness and thinking level lives in the env file read by the script: `~/.config/herdr/scripts/.env` if present, otherwise the checked-in template `~/.config/herdr/scripts/.env.example`, otherwise built-in defaults. Values are read with grep, and same-named shell environment variables override the file. The `.env.example` template ships with these defaults:

```zsh
HERDR_4TAB_HARNESS_ORDER="claude codex opencode"
HERDR_4TAB_CLAUDE_HIGH="claude --permission-mode acceptEdits --model opus --effort max"
HERDR_4TAB_CODEX_HIGH="codex --approve-for-me -m gpt-5.6-sol -c model_reasoning_effort=high"
HERDR_4TAB_OPENCODE_HIGH="opencode --auto --variant high -m opencode-go/gpt-5.6-sol"
HERDR_4TAB_CLAUDE_LOW="claude --permission-mode acceptEdits --model haiku"
HERDR_4TAB_CODEX_LOW="codex --approve-for-me -m gpt-5.4-mini"
HERDR_4TAB_OPENCODE_LOW="opencode --auto -m opencode/deepseek-v4-flash-free"
```

Customize the workspace labels, cwd, harness priority, or agent commands by copying the template to `~/.config/herdr/scripts/.env` and editing it there (`.env` is git-ignored; `make herdr-sync` seeds it from `.env.example` on first sync):

```zsh
HERDR_4TAB_HARNESS_ORDER="codex opencode claude"
HERDR_4TAB_WORKSPACE_LABEL="project-agents"
HERDR_4TAB_CWD="$HOME/project"
HERDR_4TAB_TAB1_LABEL="agent-high"
HERDR_4TAB_TAB2_LABEL="git"
HERDR_4TAB_TAB3_LABEL="shell"
HERDR_4TAB_TAB4_LABEL="agent-low"
```

### Optional developer plugins

`./herdr.zsh` also offers recommended Herdr plugins for developer workflows. The prompt accepts one number, multiple comma/space-separated numbers, `0` for all, or Enter to skip:

```text
0) Install all recommended plugins
1) reviewr — persiyanov/herdr-reviewr
2) Sessionizer — andrewchng/herdr-sessionizer
3) Browser — ogulcancelik/herdr-browser
4) Focus Notify — yankewei/herdr-focus-notify

Select plugins to install (0 for all, comma/space-separated numbers, Enter to skip): 1, 2, 3
```

The installer runs `herdr plugin install <owner/repo>` for each selected plugin, lets Herdr show its install preview, skips already installed plugins, and appends keybindings only for plugins that are installed successfully or already present.

| Plugin | Purpose | Added keys |
|--------|---------|------------|
| `persiyanov/herdr-reviewr` | Review agent-written diffs beside the chat | `prefix+alt+r` toggles reviewr |
| `andrewchng/herdr-sessionizer` | Fuzzy-open projects and Git worktrees | `prefix+alt+s` opens Sessionizer; `prefix+alt+w` opens the worktree picker |
| `ogulcancelik/herdr-browser` | Open localhost pages in a Herdr browser pane | `prefix+alt+b` opens localhost in Herdr Browser |
| `yankewei/herdr-focus-notify` | Clickable macOS notifications that focus agent panes | `prefix+alt+n` sends a test focus notification |

Check what is installed with `herdr plugin list`. After new plugin keybindings are added, reload Herdr with `herdr server reload-config` or `prefix+shift+r`, then confirm them in `prefix+?`.

`ctrl+click` opens links in panes (OSC 8 hyperlinks and visible URLs) when mouse capture is enabled.

---

## Customizing Keybindings

All bindings live in `~/.config/herdr/config.toml` under `[keys]`. Two binding syntaxes exist:

- `"prefix+n"` — requires the prefix first.
- `"ctrl+alt+n"` — a **direct chord**: fires immediately, no prefix.

On macOS, `alt` means the **Option** key (`⌥`) physically, but Herdr config still spells the modifier as `alt`, not `option`. Some terminals use Option for typing special characters instead of sending Alt/Meta key events; if an `alt+...` binding does nothing, check your terminal keyboard settings and enable the option that treats Option as Meta/Alt. This setup avoids active `alt` bindings for core navigation because `Option+1` commonly becomes a special character on macOS layouts.

### Example: bind the unbound actions

```toml
[keys]
prefix = "ctrl+b"
last_pane = "prefix+backtick"          # jump between two panes
previous_workspace = "prefix+left"
next_workspace = "prefix+right"
switch_workspace = ""                  # use prefix+g or previous/next workspace
close_workspace = "prefix+ctrl+x"       # close the current workspace after confirmation
previous_agent = "prefix+shift+up"
next_agent = "prefix+shift+down"
focus_agent = "prefix+ctrl+1..9"        # jump straight to agent 1-9

[[keys.command]]
key = "prefix+ctrl+w"
type = "shell"
command = "~/.config/herdr/scripts/new-workspace-4-tabs.zsh"
description = "create workspace with 3 command tabs"
```

If you install the optional developer plugins through `./herdr.zsh`, the installer appends matching `plugin_action` bindings for the plugins you selected:

```toml
[[keys.command]]
key = "prefix+alt+r"
type = "plugin_action"
command = "persiyanov.reviewr.toggle"
description = "toggle reviewr"

[[keys.command]]
key = "prefix+alt+s"
type = "plugin_action"
command = "sessionizer.open"
description = "open sessionizer"

[[keys.command]]
key = "prefix+alt+w"
type = "plugin_action"
command = "sessionizer.worktree-open"
description = "open sessionizer worktree picker"

[[keys.command]]
key = "prefix+alt+b"
type = "plugin_action"
command = "official.browser.open-localhost"
description = "open localhost in Herdr browser"

[[keys.command]]
key = "prefix+alt+n"
type = "plugin_action"
command = "herdr-focus-notify.test"
description = "send test focus notification"
```

Apply with `herdr server reload-config` (or `prefix+shift+r`), then confirm in `prefix+?`.

### Direct (prefix-free) chords

Prefix bindings are safest when running OpenCode inside Herdr because they do not steal keys from the OpenCode TUI. If you still want direct pane movement, choose chords that do not overlap OpenCode's defaults:

```toml
[keys]
focus_pane_left  = "ctrl+alt+h"
focus_pane_down  = "ctrl+alt+j"
focus_pane_up    = "ctrl+alt+i"
focus_pane_right = "ctrl+alt+l"
new_tab          = "ctrl+alt+c"
zoom             = "ctrl+alt+z"
```

Avoid system-owned chords: `ctrl+alt` + arrows, `t`, `l`, `a`, `s`, `u`, and `f1`–`f12`. In general, `ctrl+letter`, function keys, and explicit modified chords are the most reliable; `alt+...`, `cmd`/`super`, and punctuation-with-modifiers depend on your terminal (and on tmux, if Herdr runs inside it).

Do not map Herdr actions to OpenCode's default direct shortcuts: `ctrl+alt+k`, `ctrl+alt+[`, `ctrl+alt+]`, `ctrl+alt+b`, `ctrl+alt+f`, `ctrl+alt+d`, `ctrl+alt+u`, `ctrl+alt+e`, `ctrl+alt+g`, or `ctrl+alt+y`.

### Custom commands on keys

Bind arbitrary commands to keys — three launch types:

```toml
[[keys.command]]
key = "prefix+alt+g"
type = "popup"        # session-modal terminal; layout untouched
command = "lazygit"
width = "80%"
height = "80%"

[[keys.command]]
key = "prefix+alt+t"
type = "pane"         # temporary zoomed pane, closes when the command exits
command = "just test"

[[keys.command]]
key = "prefix+alt+m"
type = "shell"        # runs detached in the background
command = "just build"
```

For installed plugins, use `type = "plugin_action"` and the plugin action id from `herdr plugin action list`:

```toml
[[keys.command]]
key = "prefix+alt+r"
type = "plugin_action"
command = "persiyanov.reviewr.toggle"
description = "toggle reviewr"
```

### Indexed shortcuts (legacy)

```toml
[keys.indexed]
tabs = "ctrl"         # ctrl+1..9 switches tabs directly
workspaces = "ctrl+shift"
agents = "alt"
```

Still parsed for compatibility — prefer `switch_tab`, `switch_workspace`, and `focus_agent` in new configs.

---

## Quick Reference

| Keys                    | Action                          |
|-------------------------|---------------------------------|
| `ctrl+b`                | Prefix (start every action)     |
| `prefix+?`              | Keybinding help overlay         |
| `prefix+v` / `prefix+-` | Split right / split down        |
| `prefix+h/j/k/l`        | Focus pane in direction         |
| `prefix+shift+h/j/k/l`  | Swap pane in direction          |
| `prefix+tab` / `prefix+shift+tab` | Cycle panes           |
| `prefix+z`              | Zoom pane (toggle)              |
| `prefix+x`              | Close pane                      |
| `prefix+r`              | Resize mode                     |
| `prefix+[`              | Copy mode (vim keys, `y` copies)|
| `prefix+e`              | Edit scrollback                 |
| `prefix+c`              | New tab                         |
| `prefix+n` / `prefix+p` | Next / previous tab             |
| `prefix+1..9`           | Jump to tab N                   |
| `prefix+shift+t` / `prefix+shift+x` | Rename / close tab  |
| `prefix+w`              | Workspace picker                |
| `prefix+g`              | Goto picker (navigate mode)     |
| `prefix+shift+n`        | New workspace                   |
| `prefix+shift+g`        | New git worktree                |
| `prefix+shift+w` / `prefix+ctrl+x` | Rename / close workspace |
| `prefix+b`              | Toggle sidebar                  |
| `prefix+o`              | Open notification target        |
| `prefix+shift+up` / `prefix+shift+down` | Previous / next agent  |
| `prefix+ctrl+1..9`    | Jump to agent N                 |
| `prefix+ctrl+w`        | Create 4-tab command workspace  |
| `prefix+alt+r`         | Toggle reviewr (optional plugin) |
| `prefix+alt+s`         | Open Sessionizer (optional plugin) |
| `prefix+alt+w`         | Open Sessionizer worktree picker (optional plugin) |
| `prefix+alt+b`         | Open localhost in Herdr Browser (optional plugin) |
| `prefix+alt+n`         | Send Focus Notify test notification (optional plugin) |
| `prefix+s`              | Settings                        |
| `prefix+shift+r`        | Reload config                   |
| `prefix+q`              | Detach (session keeps running)  |
| `ctrl+click`            | Open link in pane               |

---

## Troubleshooting

**A shortcut does nothing.**
Check `prefix+?` first — it shows the bindings actually loaded. If your binding is missing, the config didn't load: run `herdr server reload-config` and watch for TOML errors.

**`alt+...` or `cmd+...` chords don't arrive.**
Many terminals swallow or remap these. Prefer the `ctrl+alt` family, `ctrl+letter`, or function keys. If Herdr runs inside tmux, tmux may consume the chord before Herdr sees it.

**`ctrl+b` conflicts with tmux.**
If you nest Herdr inside tmux (or vice versa), change one prefix, e.g. `prefix = "ctrl+a"` in Herdr's `[keys]`, then `herdr server reload-config`.

**Keys go to the terminal instead of Herdr.**
The prefix window applies to the *next* keypress only. Press the prefix again — or use the mouse; every keyboard action has a mouse equivalent.

**Changed the config but nothing happened.**
Reload is not automatic: `herdr server reload-config` from any shell, or `prefix+shift+r` from inside Herdr.

**An optional plugin shortcut appears but does nothing.**
Confirm the plugin is installed with `herdr plugin list`, then check its actions with `herdr plugin action list`. If the plugin was installed after Herdr started, reload config with `prefix+shift+r`. If `prefix+?` does not show the binding, rerun `./herdr.zsh` and select the plugin again, or uncomment the matching suggested binding in `~/.config/herdr/config.toml`.

---

## Next Steps

- Run `./herdr.zsh` to install Herdr, set up agent integrations, and optionally install recommended developer plugins (this repo).
- Read `herdr agent --help` for scripting agents from the CLI (`herdr agent prompt`, `herdr agent wait`, ...).
- Read `herdr plugin --help` and `herdr plugin action list` for installed plugin actions.
- Official docs: [herdr.dev/docs/keyboard](https://herdr.dev/docs/keyboard/) and [herdr.dev/docs/configuration](https://herdr.dev/docs/configuration/).
