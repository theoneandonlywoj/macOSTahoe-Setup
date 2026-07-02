#!/bin/zsh
# === container_tui.zsh ===
# Purpose: Install container management TUI tools (lazydocker, ctop) on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting container TUI tools installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install lazydocker ===
echo
echo "📥 Installing lazydocker via Homebrew..."
if command -v lazydocker >/dev/null 2>&1; then
  echo "ℹ️  lazydocker is already installed. Upgrading to latest..."
  brew upgrade lazydocker 2>/dev/null || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install lazydocker
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install lazydocker"
    exit 1
  fi
fi
echo "✅ lazydocker installed."

# === 3. Install ctop ===
echo
echo "📥 Installing ctop via Homebrew..."
if command -v ctop >/dev/null 2>&1; then
  echo "ℹ️  ctop is already installed. Upgrading to latest..."
  brew upgrade ctop 2>/dev/null || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install ctop
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install ctop"
    exit 1
  fi
fi
echo "✅ ctop installed."

# === 4. Verify installations ===
echo
echo "🧪 Verifying installations..."

lazydocker_path=$(which lazydocker 2>/dev/null)
if [[ -n "$lazydocker_path" ]]; then
  lazydocker_version=$(lazydocker --version 2>/dev/null | head -1)
  echo "📌 lazydocker: $lazydocker_path ($lazydocker_version)"
else
  echo "❌ lazydocker not found in PATH."
fi

ctop_path=$(which ctop 2>/dev/null)
if [[ -n "$ctop_path" ]]; then
  echo "📌 ctop: $ctop_path"
else
  echo "❌ ctop not found in PATH."
fi

# === 5. Wrap-up ===
echo
echo "✅ Container TUI tools installed successfully!"
echo
echo "💡 Usage:"
echo "   • Manage containers (Podman/Docker):  lazydocker"
echo "   • Container resource monitor:           ctop"
echo
echo "   Note: lazydocker auto-detects Podman via DOCKER_HOST."
echo "   If using Podman, ensure the Podman machine is running:"
echo "     podman machine start"
echo
echo "   ctop works with both Docker and Podman runtimes."
echo
echo "🎉 Installation finished successfully!"