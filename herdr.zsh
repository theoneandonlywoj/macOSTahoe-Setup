#!/bin/zsh
# === herdr.zsh ===
# Purpose: Install Herdr (terminal agent multiplexer, https://herdr.dev) on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Herdr installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install Herdr ===
echo
echo "📥 Installing Herdr via Homebrew..."
if command -v herdr >/dev/null 2>&1; then
  echo "✅ Herdr is already installed. Skipping installation."
else
  brew install herdr
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install Herdr"
    exit 1
  fi
  echo "✅ Herdr installed."
fi

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

herdr_path=$(which herdr 2>/dev/null)
if [[ -z "$herdr_path" ]]; then
  echo "❌ Herdr not found in PATH."
  exit 1
fi
echo "📌 Herdr: $herdr_path"

herdr_version=$(herdr --version 2>/dev/null | head -1)
if [[ -n "$herdr_version" ]]; then
  echo "📌 Version: $herdr_version"
fi

# === 4. Wrap-up ===
echo
echo "✅ Herdr installed successfully!"
echo
echo "💡 Usage:"
echo "   • Start server (background service):  brew services start herdr"
echo "   • Start server (foreground):          herdr server"
echo "   • Create a workspace:                 herdr workspace create --cwd ~/project --label api"
echo "   • Create a tab:                       herdr tab create --label logs"
echo "   • Split a pane:                       herdr pane split 1-1 --direction right"
echo "   • Run a command in a pane:            herdr pane run 1-2 \"just test\""
echo "   • Attach to a remote box:             herdr --remote <host>"
echo
echo "🎉 Installation finished successfully!"
