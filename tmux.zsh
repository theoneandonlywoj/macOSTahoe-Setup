#!/bin/zsh
# === tmux.zsh ===
# Purpose: Install tmux terminal multiplexer on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting tmux installation on macOS Tahoe..."
echo

# === Configuration ===
brew_path="/opt/homebrew/bin/brew"

arch_name=$(uname -m)
if [[ "$arch_name" == "arm64" ]]; then
  tmux_bin="/opt/homebrew/bin/tmux"
else
  tmux_bin="/usr/local/bin/tmux"
fi

echo "📦 Target binary: $tmux_bin"
echo

# === 1. Check if tmux is already installed ===
if command -v tmux >/dev/null 2>&1; then
  echo "✅ tmux is already installed: $(tmux -V)"
  read "reinstall?Do you want to reinstall? [y/N] "
  if [[ "$reinstall" != "y" && "$reinstall" != "Y" ]]; then
    echo "⚠️  Skipping tmux installation."
    exit 0
  fi
  echo "📦 Removing existing tmux installation..."
  brew uninstall tmux
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to remove tmux."
    exit 1
  fi
  echo "✅ tmux removed."
fi

# === 2. Check and install Homebrew if missing ===
echo
if ! command -v brew >/dev/null 2>&1; then
  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "💡 Adding Homebrew to PATH..."
  if [[ -d "/opt/homebrew/bin" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed."
else
  echo "✅ Homebrew already installed."
fi

# === 3. Install tmux ===
echo
echo "📥 Installing tmux..."
brew install tmux
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install tmux."
  exit 1
fi
echo "✅ tmux installed."

# === 4. Verify installation ===
echo
echo "🧪 Verifying installation..."
if command -v tmux >/dev/null 2>&1; then
  echo "✅ tmux installed successfully: $(tmux -V)"
else
  echo "❌ tmux installation verification failed."
  exit 1
fi

# === 5. Create starter tmux config ===
echo
echo "🔧 Setting up tmux configuration..."

tmux_conf="$HOME/.tmux.conf"

if [[ -f "$tmux_conf" ]]; then
  echo "✅ ~/.tmux.conf already exists. Skipping config creation."
else
  echo "💡 Creating starter ~/.tmux.conf..."
  cat > "$tmux_conf" <<'EOF'
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

# Clipboard integration (macOS)
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

# Status bar
set -g status-position top
set -g status-style fg=white,bg=black
EOF
  echo "✅ ~/.tmux.conf created."
fi

# === 6. Post-installation checks ===
echo
echo "🧪 Verifying setup..."
tmux -V >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "✅ tmux is ready to use."
else
  echo "⚠️  tmux command not found in PATH. Restart your terminal or run:"
  echo '   source ~/.zshrc'
fi

# === 7. Tips ===
echo
echo "🎉 tmux installation complete!"
echo
echo "💡 tmux is a terminal multiplexer: run multiple sessions in one window."
echo "💡 Launch: tmux"
echo
echo "💡 Essential key bindings (prefix: Ctrl+a):"
echo "   - Ctrl+a d       Detach (session keeps running)"
echo "   - tmux attach    Reattach to a session"
echo "   - Ctrl+a c       New window"
echo "   - Ctrl+a n/p     Next/previous window"
echo "   - Ctrl+a |       Split pane vertically"
echo "   - Ctrl+a -       Split pane horizontally"
echo "   - Ctrl+a arrow   Navigate between panes"
echo
echo "💡 Tips:"
echo "   - Use tmux for long-running tasks (survives disconnects)"
echo "   - Edit ~/.tmux.conf for custom key bindings and themes"
echo "   - Reload config inside tmux: Ctrl+a r"