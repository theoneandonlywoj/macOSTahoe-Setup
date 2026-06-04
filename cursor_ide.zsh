#!/bin/zsh
# === cursor_ide.zsh ===
# Purpose: Install Cursor AI code editor on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting installation of Cursor AI (the vibe-coding editor) on macOS Tahoe..."
echo

# === Configuration ===
cursor_app="/Applications/Cursor.app"
echo "📂 Target installation path: $cursor_app"
echo

# === 1. Check for Homebrew ===
if command -v brew >/dev/null 2>&1; then
  echo "🍺 Homebrew detected."
  echo "📦 Installing Cursor via Homebrew Cask..."
  brew install --cask cursor
  if [[ $? -eq 0 ]]; then
    echo "✅ Cursor installed successfully via Homebrew!"
  else
    echo "❌ Failed to install Cursor via Homebrew."
    exit 1
  fi
else
  echo "❌ Homebrew not found."
  echo
  echo "📋 Please install Homebrew first:"
  echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  echo
  echo "   Then run this script again."
  exit 1
fi

# === 2. Verify installation ===
if [[ ! -d "$cursor_app" ]]; then
  echo "❌ Cursor installation failed."
  exit 1
fi

echo
echo "🚀 Cursor installed at: $cursor_app"

# === 3. Verification and wrap-up ===
echo
echo "🧪 Verifying installation..."
echo "✅ Cursor installation confirmed at $cursor_app"

echo
echo "🎉 Cursor AI installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch Cursor via Launchpad or Spotlight (⌘ Space → 'Cursor')"
echo "   • Run dock_cleanup.zsh to add Cursor to your Dock"
echo "   • Enjoy your AI-powered coding environment!"