#!/bin/zsh
# === lazygit.zsh ===
# Purpose: Install lazygit (terminal Git TUI) on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🌿 Starting lazygit installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install lazygit ===
echo
echo "📥 Installing lazygit via Homebrew..."
if command -v lazygit >/dev/null 2>&1; then
  echo "ℹ️  lazygit is already installed. Upgrading to latest..."
  brew upgrade lazygit 2>/dev/null || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install lazygit
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install lazygit"
    exit 1
  fi
fi
echo "✅ lazygit installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

lazygit_path=$(which lazygit 2>/dev/null)
if [[ -z "$lazygit_path" ]]; then
  echo "❌ lazygit not found in PATH."
  exit 1
fi
echo "📌 lazygit: $lazygit_path"

lazygit_version=$(lazygit --version 2>/dev/null | head -1)
if [[ -n "$lazygit_version" ]]; then
  echo "📌 Version: $lazygit_version"
fi

# === 4. Wrap-up ===
echo
echo "✅ lazygit installed successfully!"
echo
echo "💡 Usage (complements gh.zsh + git.zsh):"
echo "   • Launch in repo:         lazygit"
echo "   • Stage files:            space (toggle), a (stage all)"
echo "   • Commit:                 c"
echo "   • Push/pull:              p / P"
echo "   • Branches panel:         b   (rebase, checkout, merge)"
echo "   • Logs:                   l"
echo "   • Quit:                   q"
echo
echo "🎉 Installation finished successfully!"
