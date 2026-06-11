# Tmux Beginner's Guide

A step-by-step guide to tmux — from installation to real-world Elixir/Phoenix/Nerves workflows.

---

## Table of Contents

1. [What is tmux?](#what-is-tmux)
2. [Installation](#installation)
3. [Core Concepts](#core-concepts)
4. [The Prefix Key](#the-prefix-key)
5. [Your First Session](#your-first-session)
6. [Windows](#windows)
7. [Panes](#panes)
8. [Copy Mode](#copy-mode)
9. [Customization](#customization)
10. [Plugins (tpm)](#plugins-tpm)
11. [Elixir / Phoenix / Nerves Workflows](#elixir--phoenix--nerves-workflows)
12. [Quick Reference](#quick-reference)
13. [Troubleshooting](#troubleshooting)

---

## What is tmux?

**tmux** is a terminal multiplexer. It lets you create multiple terminal sessions inside a single terminal window, and those sessions persist even if you close the window or disconnect from SSH.

Think of it as tabs and splits for your terminal — but they survive disconnects, crashes, and reboots (with plugins).

**Why you need it:**

- Run a Phoenix server, IEx session, and tests side by side in one window
- SSH into a remote machine, start a build, disconnect, and reattach later — your process is still running
- Save your entire layout (panes, windows, running programs) and restore it after a reboot
- Switch between projects instantly with named sessions

---

## Installation

Run the automated installer from this repository:

```zsh
chmod +x tmux.zsh
./tmux.zsh
```

The installer will:

1. **Check for an existing tmux** — if tmux is already installed, it asks whether to reinstall
2. **Check and install Homebrew** — if Homebrew is missing, it installs it automatically
3. **Install tmux** via Homebrew
4. **Back up any existing** `~/.tmux.conf` — saved as `~/.tmux.conf.backup.YYYYMMDDHHMMSS`
5. **Create a starter** `~/.tmux.conf` with all plugins and settings
6. **Install [tpm](https://github.com/tmux-plugins/tpm)** and all plugins automatically

**Manual installation:**

```zsh
brew install tmux
```

---

## Core Concepts

tmux has three levels of organization:

```
Session
├── Window 1 (like a browser tab)
│   ├── Pane 1 (top-left)
│   ├── Pane 2 (top-right)
│   └── Pane 3 (bottom)
├── Window 2
│   └── Pane 1 (full pane)
└── Window 3
    └── Pane 1
```

| Level    | What it is                        | Analogy              |
|----------|-----------------------------------|----------------------|
| Session  | A collection of windows           | A workspace/project  |
| Window   | A single screen with panes        | A browser tab        |
| Pane     | An individual terminal            | A split within a tab |

**Key insight:** A session can have many windows, and each window can have many panes. When you detach from a session, everything keeps running in the background.

---

## The Prefix Key

Every tmux command starts with a **prefix key**. The default is `Ctrl+b`, but our config changes it to `Ctrl+a` (easier to reach, standard in most tmux guides).

**How it works:**

1. Press `Ctrl+a` (the prefix)
2. Release both keys
3. Press the command key (e.g., `d` to detach)

**Notation used in this guide:**

- `Ctrl+a d` — means: press `Ctrl+a`, release, then press `d`
- `Ctrl+a |` — means: press `Ctrl+a`, release, then press `|`

> If you ever need to send a literal `Ctrl+a` to a program inside tmux (e.g., in a shell), press `Ctrl+a` twice — our config passes it through with `bind C-a send-prefix`.

---

## Your First Session

### Create a session

```zsh
tmux                        # unnamed session
tmux new -s myproject       # named session
```

You're now inside tmux. The status bar at the top shows your session and windows.

### Detach (session keeps running)

```
Ctrl+a d
```

You're back at your regular terminal. The session is still running in the background.

### List sessions

```zsh
tmux ls
```

Output example:

```
myproject: 1 windows (created Sat Jun  6 10:00:00 2026)
dev: 2 windows (created Sat Jun  6 09:45:00 2026)
```

### Reattach

```zsh
tmux attach                 # attach to the only session
tmux attach -t myproject    # attach to a named session
tmux a -t myproject         # shorthand
```

### Kill a session

```zsh
tmux kill-session -t myproject
```

Or from inside tmux:

```
Ctrl+a :kill-session
```

---

## Windows

Windows are like browser tabs — each is a full-screen terminal within a session.

| Action                  | Key / Command         |
|-------------------------|-----------------------|
| New window              | `Ctrl+a c`            |
| Next window             | `Ctrl+a n`            |
| Previous window         | `Ctrl+a p`            |
| Switch to window by #   | `Ctrl+a 0` – `Ctrl+a 9` |
| Rename window           | `Ctrl+a ,`            |
| List all windows        | `Ctrl+a w`            |
| Kill current window     | `Ctrl+a &`            |

**Tip:** Name your windows for context — `server`, `tests`, `iex` — with `Ctrl+a ,`.

---

## Panes

Panes let you split a window into multiple terminals.

### Splitting

| Action                        | Key               |
|-------------------------------|-------------------|
| Split vertically (side by side) | `Ctrl+a \|`    |
| Split horizontally (top/bottom)  | `Ctrl+a -`     |

Our config opens new panes in the same directory as the current pane.

### Navigation

| Action                     | Key                   |
|----------------------------|-----------------------|
| Move between panes         | `Ctrl+a arrow key`    |
| Move between panes (no prefix) | `Alt+arrow` or `Ctrl+arrow` |
| Cycle through panes        | `Ctrl+a o`            |
| Show pane numbers          | `Ctrl+a q`            |

### Resize (from pain-control plugin)

| Action                     | Key                   |
|----------------------------|-----------------------|
| Resize pane left           | `Ctrl+a H`            |
| Resize pane right          | `Ctrl+a L`            |
| Resize pane down           | `Ctrl+a J`            |
| Resize pane up             | `Ctrl+a K`            |

### Other

| Action                     | Key                   |
|----------------------------|-----------------------|
| Zoom pane (fullscreen)     | `Ctrl+a z`            |
| Swap pane with previous    | `Ctrl+a {`            |
| Swap pane with next        | `Ctrl+a }`            |
| Break pane into window     | `Ctrl+a @`            |
| Kill current pane          | `Ctrl+a x`            |

### Deleting / Killing

| Action                       | Key / Command              |
|------------------------------|----------------------------|
| Kill current pane            | `Ctrl+a x`                 |
| Kill pane (no confirmation)  | `Ctrl+a X` (uppercase)     |
| Kill current window          | `Ctrl+a &`                 |
| Last window closes session   | Kill the last window or run `Ctrl+a :kill-session` |

> Press `y` to confirm when prompted after `Ctrl+a x` or `Ctrl+a &`. Use `Ctrl+a X` (uppercase, from pain-control) to skip the confirmation dialog.

---

## Copy Mode

Copy mode lets you scroll through pane output, select text, and copy it.

### Enter and exit

| Action                     | Key                   |
|----------------------------|-----------------------|
| Enter copy mode            | `Ctrl+a [`            |
| Exit copy mode             | `q`                   |

### Navigation (vi-style keys)

| Action                     | Key                   |
|----------------------------|-----------------------|
| Move up/down/left/right    | `k` / `j` / `h` / `l` |
| Page up                    | `Ctrl+u`              |
| Page down                  | `Ctrl+d`              |
| Go to top                  | `g`                   |
| Go to bottom               | `G`                   |
| Search forward             | `?` (then type query, Enter) |
| Search backward            | `/` (then type query, Enter) |

### Select and copy

| Action                     | Key                   |
|----------------------------|-----------------------|
| Start selection            | `Space`               |
| Copy selection             | `Enter`               |
| Paste                      | `Ctrl+a ]`            |

> With the **tmux-yank** plugin, copied text also goes to your macOS clipboard automatically. Mouse drag to select also copies to clipboard.

---

## Customization

The installer creates `~/.tmux.conf`. Edit it to customize tmux.

After making changes, reload inside tmux:

```
Ctrl+a r
```

Or from the command line:

```zsh
tmux source-file ~/.tmux.conf
```

### What our starter config provides

| Setting               | Value                  | Why                       |
|-----------------------|------------------------|---------------------------|
| Prefix key            | `Ctrl+a`               | Easier to reach than default `Ctrl+b` |
| Default shell         | `/bin/zsh`              | macOS default              |
| Default terminal      | `screen-256color`       | Proper color support in terminal |
| Mouse support         | `on`                   | Click to select panes, scroll to navigate |
| Window/pane numbering | Starts at `1`          | Keyboard-friendly (`1` is leftmost) |
| Renumber windows      | `on`                   | Windows renumber when one is closed |
| History limit         | `10000` lines          | More scrollback             |
| Escape time           | `0`                    | No delay for escape key — faster key response |
| Display panes time    | `2000` ms              | Pane numbers visible for 2 seconds |
| Split bindings        | `\|` and `-`            | Mnemonic (vertical/horizontal) |
| New pane/window       | Same directory         | Stay in your project       |
| Status bar            | Top, white on black    | Clean, easy to read         |

### Full config file

The installer generates the following `~/.tmux.conf`:

```tmux
# === tmux.conf ===
# Starter configuration for tmux on macOS Tahoe

# General
set -g default-shell /bin/zsh
set -g default-terminal "screen-256color"
set -g history-limit 10000
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g display-panes-time 2000
set -g escape-time 0

# Prefix key (Ctrl+a is more ergonomic than Ctrl+b)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# New windows retain current path
bind c new-window -c "#{pane_current_path}"

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Switch panes using Ctrl-arrow without prefix
bind -n C-Left select-pane -L
bind -n C-Right select-pane -R
bind -n C-Up select-pane -U
bind -n C-Down select-pane -D

# Reload config file
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Status bar
set -g status-position top
set -g status-style fg=white,bg=black

# === Plugins (tpm) ===
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-pain-control'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-copycat'
set -g @plugin 'tmux-plugins/tmux-open'
set -g @plugin 'tmux-plugins/tmux-fzf'

# === Plugin settings ===
# Resurrect: restore Elixir/Phoenix/Nerves processes
set -g @resurrect-processes ':iex :mix :node :erl :npm :docker'
set -g @resurrect-capture-pane-contents 'on'

# Continuum: auto-save every 15 min, auto-restore on start
set -g @continuum-save-interval '15'
set -g @continuum-restore 'on'

# Initialize tpm (must be last line)
run '~/.tmux/plugins/tpm/tpm'
```

---

## Plugins (tpm)

The installer sets up [tpm](https://github.com/tmux-plugins/tpm) (Tmux Plugin Manager) and installs all plugins automatically.

### Managing plugins

| Action                       | Key                     |
|------------------------------|-------------------------|
| Install new plugins          | `Ctrl+a I`              |
| Update plugins               | `Ctrl+a U`              |
| Remove unused plugins        | `Ctrl+a alt+u`          |

After adding a plugin to `~/.tmux.conf`, press `Ctrl+a I` to install it.

### Installed plugins

| Plugin                  | What it does                                                       |
|-------------------------|--------------------------------------------------------------------|
| tmux-resurrect          | Save and restore entire tmux sessions (panes, windows, running programs) |
| tmux-continuum          | Auto-saves sessions every 15 min, auto-restores on tmux start     |
| tmux-pain-control       | Better pane management — resize with `H/J/K/L`, swap, breakpoint    |
| tmux-yank               | Copy to macOS system clipboard from tmux — mouse drag, selection   |
| tmux-copycat            | Regex search across pane content — search stacktraces, errors, URLs |
| tmux-open                | Open highlighted `file:line` in your `$EDITOR`                     |
| tmux-fzf                | FZF-powered session/window/pane switcher                            |

### Plugin configuration in our setup

```tmux
# Resurrect: restore Elixir/Phoenix/Nerves processes
set -g @resurrect-processes ':iex :mix :node :erl :npm :docker'
set -g @resurrect-capture-pane-contents 'on'

# Continuum: auto-save every 15 min, auto-restore on start
set -g @continuum-save-interval '15'
set -g @continuum-restore 'on'
```

This means `iex`, `mix`, `node`, `erl`, `npm`, and `docker` processes are preserved across session restores.

---

## Elixir / Phoenix / Nerves Workflows

### Phoenix dev layout

A typical Phoenix development session:

```zsh
# Start a named session
tmux new -s phoenix

# You're now in Window 1 → run the Phoenix server
mix phx.server

# Split vertically for IEx
Ctrl+a |
# In the new pane:
iex -S mix

# Split the IEx pane horizontally for tests
Ctrl+a -
# In the new pane:
mix test --stale

# Rename windows for context
Ctrl+a ,          → type "server"
Ctrl+a c          → new window
Ctrl+a ,          → type "iex"
```

Result:

```
┌─────────────────┬─────────────────┐
│                  │     iex -S mix  │
│  mix phx.server  ├─────────────────┤
│                  │ mix test --stale│
└─────────────────┴─────────────────┘
```

### Nerves firmware workflow

```zsh
tmux new -s nerves

# Window 1: Editor
Ctrl+a ,    → type "editor"

# Window 2: Build + upload
Ctrl+a c
Ctrl+a ,    → type "firmware"
# Pane 1: Build
mix firmware
# Pane 2: Upload (split)
Ctrl+a -
mix upload <target_ip>
```

### Long-running tasks

Use tmux for any process you don't want to lose:

```zsh
tmux new -s deploy

# Start a long deploy
mix deploy production

# Detach — go back to your terminal
Ctrl+a d

# Hours later, reattach
tmux attach -t deploy
```

This works for:

- `mix test` suites that take minutes
- `mix firmware` builds for Nerves targets
- SSH sessions where you're running remote commands
- `mix phx.server` development servers
- Docker container logs: `docker compose logs -f`

### Session-per-project pattern

Name sessions after your projects for fast switching:

```zsh
tmux new -s frontend     # Phoenix frontend
tmux new -s api          # API server
tmux new -s firmware     # Nerves target
tmux new -s infra         # DevOps / deployment
```

Switch between them:

```
Ctrl+a s            # Interactive session picker
Ctrl+a (             # Previous session
Ctrl+a )             # Next session
```

Or from the command line:

```zsh
tmux switch -t frontend
```

### Session persistence with resurrect and continuum

**Manual save and restore:**

```
Ctrl+a Ctrl+s        # Save session now
Ctrl+a Ctrl+r        # Restore last saved session
```

**Automatic (configured in our setup):**

- **Continuum** saves your session every 15 minutes automatically
- **Continuum** restores your last session when tmux starts

This means after a reboot, running `tmux` brings back exactly where you left off — all panes, windows, and running processes restored.

### Searching with copycat

Search for stack traces, error messages, and more:

```
Ctrl+a /              # Search (using copycat)
```

Examples:

- Search for error keywords in build output
- Find a specific `file.ex:42` line in a stacktrace, then use `tmux-open` to jump to it in your editor
- Search for URLs in log output

---

## Quick Reference

### Prefix key

All commands start with `Ctrl+a` (press and release, then press the command key).

### Sessions

| Action                     | Command / Key          |
|----------------------------|------------------------|
| New session                | `tmux new -s name`     |
| List sessions              | `tmux ls`              |
| Attach to session          | `tmux a -t name`       |
| Detach                     | `Ctrl+a d`             |
| Rename session             | `Ctrl+a $`             |
| Session switcher           | `Ctrl+a s`             |
| Kill session               | `tmux kill-session -t name` |
| Previous session           | `Ctrl+a (`             |
| Next session               | `Ctrl+a )`             |

### Windows

| Action                     | Key                    |
|----------------------------|------------------------|
| New window                 | `Ctrl+a c`             |
| Next / previous            | `Ctrl+a n` / `Ctrl+a p` |
| Switch by number           | `Ctrl+a 0` – `Ctrl+a 9` |
| Rename window              | `Ctrl+a ,`             |
| List windows               | `Ctrl+a w`             |
| Kill window                | `Ctrl+a &`             |

### Panes

| Action                     | Key                    |
|----------------------------|------------------------|
| Split vertically           | `Ctrl+a \|`            |
| Split horizontally         | `Ctrl+a -`             |
| Navigate panes             | `Ctrl+a arrow`         |
| Navigate (no prefix)       | `Alt+arrow` / `Ctrl+arrow` |
| Resize pane                | `Ctrl+a H/J/K/L`      |
| Zoom (fullscreen toggle)   | `Ctrl+a z`             |
| Swap pane                  | `Ctrl+a {` / `Ctrl+a }` |
| Break pane into window     | `Ctrl+a @`             |
| Show pane numbers          | `Ctrl+a q`             |
| Kill pane                  | `Ctrl+a x`             |
| Kill pane (no confirm)     | `Ctrl+a X` (uppercase) |

### Copy mode

| Action                     | Key                    |
|----------------------------|------------------------|
| Enter copy mode            | `Ctrl+a [`             |
| Exit copy mode             | `q`                    |
| Start selection            | `Space`                |
| Copy and exit              | `Enter`                |
| Paste                      | `Ctrl+a ]`             |
| Search                     | `Ctrl+a /` (copycat)   |

### Misc

| Action                     | Key                    |
|----------------------------|------------------------|
| Reload config              | `Ctrl+a r`             |
| Command mode               | `Ctrl+a :`             |
| List all bindings          | `Ctrl+a ?`             |
| Install plugins (tpm)      | `Ctrl+a I`             |
| Update plugins (tpm)       | `Ctrl+a U`             |
| Remove unused plugins      | `Ctrl+a alt+u`         |
| Save session (resurrect)   | `Ctrl+a Ctrl+s`        |
| Restore session (resurrect)| `Ctrl+a Ctrl+r`        |

### Command-line

```zsh
tmux                        # Start unnamed session
tmux new -s name            # Start named session
tmux ls                     # List sessions
tmux attach -t name         # Attach to session
tmux kill-session -t name   # Kill session
tmux kill-server            # Kill all sessions
tmux source-file ~/.tmux.conf  # Reload config from CLI
```

---

## Troubleshooting

### tmux is not found after installation

Restart your terminal or run:

```zsh
source ~/.zshrc
```

### Stuck in copy mode

Press `q` to exit copy mode. Press `Esc` if `q` doesn't work.

### tmux appears frozen

This usually means a nested prefix. Try:

```
Ctrl+a Ctrl+a       # Sends a literal Ctrl+a
Ctrl+a :            # Enter command mode, type :q to quit
Ctrl+c              # Force interrupt in the current pane
```

If completely unresponsive from inside:

```zsh
tmux kill-server    # From another terminal — kills ALL sessions
tmux kill-session -t name   # Kills just one session
```

### Config changes not taking effect

Reload inside tmux:

```
Ctrl+a r
```

Or from the CLI:

```zsh
tmux source-file ~/.tmux.conf
```

### `pbcopy` not working in tmux

The **tmux-yank** plugin handles clipboard integration. Make sure it's installed:

```
Ctrl+a I
```

If issues persist, verify `pbcopy` works outside tmux:

```zsh
echo "test" | pbcopy
pbpaste
```

### tpm is not installing plugins

1. Verify tpm is cloned:

```zsh
ls ~/.tmux/plugins/tpm
```

2. Re-run plugin installation inside tmux:

```
Ctrl+a I
```

3. If tpm is missing entirely, clone it manually:

```zsh
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

4. Then install plugins:

```zsh
~/.tmux/plugins/tpm/bin/install_plugins
```

### Resurrect not restoring processes

Check that the processes are listed in `@resurrect-processes`:

```zsh
grep resurrect-processes ~/.tmux.conf
```

Our config includes:

```
set -g @resurrect-processes ':iex :mix :node :erl :npm :docker'
```

Add more processes by editing `~/.tmux.conf` and reloading with `Ctrl+a r`, then `Ctrl+a I`.

### Mouse scrolling doesn't work

Our config enables mouse support (`set -g mouse on`). If it's not working:

1. Reload config: `Ctrl+a r`
2. Check your terminal emulator supports mouse reporting
3. Try toggling mouse mode: `Ctrl+a :set -g mouse on`

### Old config conflicting

The installer backs up existing configs. Find your backup:

```zsh
ls ~/.tmux.conf.backup.*
```

To restore a backup:

```zsh
cp ~/.tmux.conf.backup.20260606100000 ~/.tmux.conf
tmux source-file ~/.tmux.conf
```