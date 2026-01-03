## macOSTahoe-Setup

Automated scripts to bootstrap a fresh macOS development environment: Git, GitHub CLI, Homebrew, containers, browsers, IDEs, language runtimes, Kubernetes tooling, and more.

Each script is intended to be run from this repository directory and is safe to run individually. You can run everything end-to-end or pick only what you need.

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
chmod +x git.sh gh.zsh brew.zsh dock_cleanup.zsh google_chrome.zsh slack.zsh cursor_ide.zsh podman.zsh docker_compose.zsh 1password.zsh mise.zsh elixir_and_erlang.zsh kubectl_and_krew.zsh kafka_cli.zsh

./git.sh
./gh.zsh
./brew.zsh
./dock_cleanup.zsh
./google_chrome.zsh
./slack.zsh
./cursor_ide.zsh
./podman.zsh
./docker_compose.zsh
./1password.zsh
./mise.zsh
./elixir_and_erlang.zsh
./kubectl_and_krew.zsh
./kafka_cli.zsh
```

## Scripts

### Core tooling

#### Git

Sets up Git with sensible defaults.

```zsh
chmod +x git.sh
./git.sh
```

#### GitHub CLI

Installs and configures the GitHub CLI (`gh`).

```zsh
chmod +x gh.zsh
./gh.zsh
```

#### Homebrew

Installs Homebrew, the macOS package manager.

```zsh
chmod +x brew.zsh
./brew.zsh
```

### Desktop & productivity

#### Dock cleanup

Cleans up the macOS Dock to a leaner default.

```zsh
chmod +x dock_cleanup.zsh
./dock_cleanup.zsh
```

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

#### Cursor IDE

Installs the Cursor IDE.

```zsh
chmod +x cursor_ide.zsh
./cursor_ide.zsh
```

#### 1Password

Installs 1Password.

```zsh
chmod +x 1password.zsh
./1password.zsh
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

## Notes & troubleshooting

- You can rerun scripts if something fails; most are designed to be safe to run multiple times.
- Some scripts may modify your `~/.zshrc`. Open a new terminal or run `source ~/.zshrc` after running them.
- If GUI apps (Chrome, Slack, 1Password, Cursor) don’t appear immediately, try logging out and back in or restarting.
- For issues with Homebrew or Xcode Command Line Tools, verify:

  ```zsh
  xcode-select -p
  brew doctor
  ```
