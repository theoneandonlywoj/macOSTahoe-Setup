#!/bin/zsh
# === tmux.zsh ===
# Purpose: Install tmux terminal multiplexer on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting tmux installation on macOS Tahoe..."
echo

# === Configuration ===
brew_path="/opt/homebrew/bin/brew"
tpm_dir="$HOME/.tmux/plugins/tpm"
tmux_conf="$HOME/.tmux.conf"

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

if [[ -f "$tmux_conf" ]]; then
  echo "💡 Existing ~/.tmux.conf found. Backing up and replacing..."
  mv "$tmux_conf" "${tmux_conf}.backup.$(date +%Y%m%d%H%M%S)"
fi

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
EOF
echo "✅ ~/.tmux.conf created."

# === 6. Install tpm and plugins ===
echo
echo "🔌 Installing Tmux Plugin Manager (tpm)..."

if [[ -d "$tpm_dir" ]]; then
  echo "💡 tpm already installed. Updating..."
  git -C "$tpm_dir" pull
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to update tpm."
    exit 1
  fi
  echo "✅ tpm updated."
else
  echo "📥 Cloning tpm..."
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to clone tpm."
    exit 1
  fi
  echo "✅ tpm cloned."
fi

echo
echo "📦 Installing tmux plugins..."
export TMUX_PLUGIN_MANAGER_PATH="$HOME/.tmux/plugins/"

tmux new-session -d -s __tmux_setup 2>/dev/null || true
sleep 1
tmux source-file "$tmux_conf" 2>/dev/null || true
sleep 1

"$tpm_dir/bin/install_plugins"
install_status=$?

tmux kill-session -t __tmux_setup 2>/dev/null || true

if [[ $install_status -ne 0 ]]; then
  echo "⚠️  Plugin installation via script had issues (this is often normal on first run)."
  echo "💡  Press Ctrl+a I inside tmux to finalize plugin installation."
  echo "✅ tmux setup complete (plugins will install on first tmux session)."
else
  echo "✅ tmux plugins installed."
fi

unset TMUX_PLUGIN_MANAGER_PATH

# === 7. Post-installation checks ===
echo
echo "🧪 Verifying setup..."
tmux -V >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "✅ tmux is ready to use."
else
  echo "⚠️  tmux command not found in PATH. Restart your terminal or run:"
  echo '   source ~/.zshrc'
fi

# === 8. Tips ===
echo
echo "🎉 tmux installation complete!"
echo
echo "💡 tmux is a terminal multiplexer: run multiple sessions in one window."
echo "💡 Launch: tmux"
echo
echo "💡 Session management:"
echo "   tmux new -s name          Create a named session"
echo "   tmux ls                   List sessions"
echo "   tmux attach -t name       Attach to a named session"
echo "   tmux kill-session -t name Kill a named session"
echo "   Ctrl+a d                  Detach from session (keeps running)"
echo "   Ctrl+a $                  Rename current session"
echo "   Ctrl+a s                  Show session switcher"
echo
echo "💡 Window management:"
echo "   Ctrl+a c       New window"
echo "   Ctrl+a n/p     Next/previous window"
echo "   Ctrl+a 0-9     Switch to window by number"
echo "   Ctrl+a ,       Rename current window"
echo "   Ctrl+a w       List all windows"
echo "   Ctrl+a &       Kill current window"
echo
echo "💡 Pane management:"
echo "   Ctrl+a |       Split pane vertically"
echo "   Ctrl+a -       Split pane horizontally"
echo "   Ctrl+a arrow   Navigate between panes"
echo "   Ctrl+a x       Kill current pane"
echo "   Ctrl+a z       Toggle pane zoom (fullscreen)"
echo "   Ctrl+a q       Display pane numbers"
echo "   Ctrl+a o       Cycle through panes"
echo "   Ctrl+a {       Swap pane with previous"
echo "   Ctrl+a }       Swap pane with next"
echo
echo "💡 Copy mode (Ctrl+a [ to enter):"
echo "   Ctrl+a [       Enter copy mode"
echo "   q              Exit copy mode"
echo "   Space          Start selection"
echo "   Enter          Copy selection (macOS: also copies to clipboard)"
echo "   Ctrl+a ]       Paste from buffer"
echo
echo "💡 Other essentials:"
echo "   Ctrl+a ?       List all key bindings"
echo "   Ctrl+a r       Reload config"
echo "   Ctrl+a :       Enter command mode"
echo
echo "💡 Workflow suggestions:"
echo "   1. Named sessions per project:"
echo "      tmux new -s frontend    # Work on frontend"
echo "      tmux new -s backend     # Work on backend"
echo "      tmux attach -t frontend # Switch context instantly"
echo
echo "   2. Dev environment layout:"
echo "      tmux new -s dev         # Start session"
echo "      Ctrl+a |                # Side-by-side panes"
echo "      Top pane: editor"
echo "      Bottom pane: tests/server"
echo
echo "   3. Persistent remote work:"
echo "      SSH into server → tmux new -s deploy"
echo "      Run long builds/deploys → Ctrl+a d"
echo "      Reconnect: tmux attach -t deploy"
echo
echo "   4. Quick session switching:"
echo "      Ctrl+a s                # Interactive session picker"
echo "      Ctrl+a ( / )            # Previous/next session"
echo
echo "💡 Tips:"
echo "   - Use tmux for long-running tasks (survives disconnects)"
echo "   - Edit ~/.tmux.conf for custom key bindings and themes"
echo "   - Reload config inside tmux: Ctrl+a r"
echo
echo "💡 Plugin management (tpm):"
echo "   Ctrl+a I         Install plugins (after adding to ~/.tmux.conf)"
echo "   Ctrl+a U         Update plugins"
echo "   Ctrl+a alt+u     Remove plugins not in ~/.tmux.conf"
echo
echo "💡 Installed plugins:"
echo "   tmux-resurrect     Save/restore sessions across restarts"
echo "   tmux-continuum      Auto-save every 15 min, auto-restore on start"
echo "   tmux-pain-control   Better pane management bindings"
echo "   tmux-yank           Copy to macOS clipboard"
echo "   tmux-copycat        Search across pane content (great for stacktraces)"
echo "   tmux-open           Open file:line from tmux in \$EDITOR"
echo "   tmux-fzf            FZF-powered session/window switcher"