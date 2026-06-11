## macOSTahoe-Setup

Automated scripts to bootstrap a fresh macOS development environment: Git, GitHub CLI, Homebrew, containers, browsers, IDEs, language runtimes, Kubernetes tooling, and more.

Each script is intended to be run from this repository directory and is safe to run individually. You can run everything end-to-end or pick only what you need.

**Important:** Run `dock_cleanup.zsh` **last** — it cleans up the Dock and adds all installed apps in the correct order.

## Prerequisites

- macOS with Zsh (default on recent macOS versions).
- Xcode or Xcode Command Line Tools:
  - Install full Xcode from the App Store, or
  - Install only the Command Line Tools:

    ```zsh
    xcode-select --install
    ```

  Some scripts (e.g., Homebrew, compilers, Git) assume Xcode Command Line Tools are available.

## Install everything (in order)

From the repository root:

```zsh
chmod +x brew.zsh vivaldi_browser.zsh git.zsh gh.zsh google_chrome.zsh slack.zsh 1password.zsh postman.zsh cursor_ide.zsh vscode_ide.zsh opencode.zsh podman.zsh docker_compose.zsh kubectl_and_krew.zsh kafka_cli.zsh mise.zsh elixir_and_erlang.zsh tidewave.zsh emacs.zsh doom_emacs.zsh dock_cleanup.zsh

./brew.zsh
./vivaldi_browser.zsh
./git.zsh
./gh.zsh
./google_chrome.zsh
./slack.zsh
./1password.zsh
./postman.zsh
./cursor_ide.zsh
./vscode_ide.zsh
./opencode.zsh
./podman.zsh
./docker_compose.zsh
./kubectl_and_krew.zsh
./kafka_cli.zsh
./mise.zsh
./elixir_and_erlang.zsh
./tidewave.zsh
./emacs.zsh
./doom_emacs.zsh
./dock_cleanup.zsh
```

## Scripts

### Core tooling

#### Homebrew

Installs Homebrew, the macOS package manager.

```zsh
chmod +x brew.zsh
./brew.zsh
```

#### Vivaldi

Installs the Vivaldi browser.

```zsh
chmod +x vivaldi_browser.zsh
./vivaldi_browser.zsh
```

#### Git

Sets up Git with sensible defaults.

```zsh
chmod +x git.zsh
./git.zsh
```

#### GitHub CLI

Installs and configures the GitHub CLI (`gh`).

```zsh
chmod +x gh.zsh
./gh.zsh
```

### Desktop & productivity

#### Google Chrome

Installs Google Chrome browser.

```zsh
chmod +x google_chrome.zsh
./google_chrome.zsh
```

#### Slack

Installs Slack.

```zsh
chmod +x slack.zsh
./slack.zsh
```

#### 1Password

Installs 1Password.

```zsh
chmod +x 1password.zsh
./1password.zsh
```

#### Postman

Installs Postman API client.

```zsh
chmod +x postman.zsh
./postman.zsh
```

### IDEs & editors

#### Cursor IDE

Installs the Cursor IDE.

```zsh
chmod +x cursor_ide.zsh
./cursor_ide.zsh
```

#### Visual Studio Code

Installs Visual Studio Code.

```zsh
chmod +x vscode_ide.zsh
./vscode_ide.zsh
```

#### OpenCode

Installs OpenCode (open-source AI coding agent) — both CLI and Desktop app.

```zsh
chmod +x opencode.zsh
./opencode.zsh
```

### Containers & Kubernetes

#### Podman (Docker replacement)

Installs Podman as a drop-in Docker replacement.

```zsh
chmod +x podman.zsh
./podman.zsh
```

#### Docker Compose

Installs Docker Compose.

```zsh
chmod +x docker_compose.zsh
./docker_compose.zsh
```

#### kubectl and krew

Installs `kubectl` and `krew` (kubectl plugin manager), and configures your shell.

```zsh
chmod +x kubectl_and_krew.zsh
./kubectl_and_krew.zsh
```

#### Kafka CLI

Installs the `kaf` Kafka CLI and configures Zsh completions.

```zsh
chmod +x kafka_cli.zsh
./kafka_cli.zsh
```

### Language runtimes & dev environment

#### Mise

Installs Mise (runtime/version manager) and configures it.

```zsh
chmod +x mise.zsh
./mise.zsh
```

#### Elixir and Erlang

Installs Elixir and Erlang (typically via Mise / package manager).

```zsh
chmod +x elixir_and_erlang.zsh
./elixir_and_erlang.zsh
```

#### Tidewave

Installs Tidewave Desktop and CLI for Apple chips / Apple Silicon Macs, with an Intel fallback. Prints Phoenix and Phoenix umbrella setup guides.

```zsh
chmod +x tidewave.zsh
./tidewave.zsh
```

#### Emacs

Installs Emacs 30 via Homebrew emacs-plus with ImageMagick support. Optionally installs git, ripgrep, and fd.

```zsh
chmod +x emacs.zsh
./emacs.zsh
```

#### Doom Emacs

Sets up Doom Emacs (clones, installs, syncs, installs Markdown and ShellCheck). Requires Emacs to be installed first (run `emacs.zsh`).

```zsh
chmod +x doom_emacs.zsh
./doom_emacs.zsh
```

### Dock setup (run last)

#### Dock cleanup and setup

Removes unwanted macOS default apps from the Dock and adds all installed apps in order: Chrome, Vivaldi, Slack, VSCode, OpenCode, Postman, 1Password. Installs `dockutil` automatically if needed. **Run this script after all app installations are complete.**

```zsh
chmod +x dock_cleanup.zsh
./dock_cleanup.zsh
```

## Makefile commands

This repo includes a Makefile for managing your Doom Emacs configuration. Run `make help` for a quick reference, or see [docs/makefile-commands.md](docs/makefile-commands.md) for full details.

| Command | Description |
|---|---|
| `make` / `make all` | Sync Doom Emacs config (back up, copy, run `doom sync`) |
| `make doom-sync` | Back up existing `~/.doom.d`, copy repo config, run `doom sync` |
| `make doom-backup` | Move `~/.doom.d` to a timestamped backup |
| `make doom-restore` | Restore the most recent backup to `~/.doom.d` |
| `make doom-diff` | Diff repo vs installed Doom config files |
| `make tmux-sync` | Back up existing `~/.tmux.conf`, copy repo config, reload in tmux |
| `make tmux-backup` | Copy `~/.tmux.conf` to a timestamped backup |
| `make tmux-restore` | Restore the most recent tmux backup |
| `make tmux-diff` | Diff repo vs installed `~/.tmux.conf` |
| `make sync` | Alias for `doom-sync` |
| `make backup` | Alias for `doom-backup` |
| `make restore` | Alias for `doom-restore` |
| `make diff` | Alias for `doom-diff` |
| `make tsync` | Alias for `tmux-sync` |
| `make tbackup` | Alias for `tmux-backup` |
| `make trestore` | Alias for `tmux-restore` |
| `make tdiff` | Alias for `tmux-diff` |
| `make soft-test` | Validate `.zsh` scripts and config files |
| `make help` | Show available commands |

## Notes & troubleshooting

- You can rerun scripts if something fails; most are designed to be safe to run multiple times.
- Some scripts may modify your `~/.zshrc`. Open a new terminal or run `source ~/.zshrc` after running them.
- If GUI apps (Chrome, Slack, 1Password, Cursor) don't appear immediately, try logging out and back in or restarting.
- Run `dock_cleanup.zsh` last — it configures the Dock with all your installed apps in the correct order.
- For issues with Homebrew or Xcode Command Line Tools, verify:

  ```zsh
  xcode-select -p
  brew doctor
  ```
