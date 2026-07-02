#!/bin/zsh
# === websocat.zsh ===
# Purpose: Install websocat for WebSocket/Phoenix Channel testing on macOS Tahoe
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting websocat installation on macOS Tahoe..."
echo

# === 1. Check Homebrew installation ===
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed. Please run brew.zsh first."
  exit 1
fi
echo "✅ Homebrew detected."

# === 2. Install websocat ===
echo
echo "📥 Installing websocat via Homebrew..."
if command -v websocat >/dev/null 2>&1; then
  echo "ℹ️  websocat is already installed. Upgrading to latest..."
  brew upgrade websocat 2>/dev/null || echo "⚠️  Upgrade skipped (already up-to-date)."
else
  brew install websocat
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install websocat"
    exit 1
  fi
fi
echo "✅ websocat installed."

# === 3. Verify installation ===
echo
echo "🧪 Verifying installation..."

websocat_path=$(which websocat 2>/dev/null)
if [[ -z "$websocat_path" ]]; then
  echo "❌ websocat not found in PATH."
  exit 1
fi
echo "📌 websocat: $websocat_path"

websocat_version=$(websocat --version 2>/dev/null)
if [[ -n "$websocat_version" ]]; then
  echo "📌 Version: $websocat_version"
fi

# === 4. Wrap-up ===
echo
echo "✅ websocat installed successfully!"
echo
echo "💡 Usage:"
echo "   • Connect to Phoenix socket:"
echo "     websocat ws://localhost:4000/socket/websocket?vsn=2.0.0"
echo
echo "   • Join a device channel:"
echo '     ["1","1","device:YOUR_DEVICE_ID","phx_join",{}]'
echo
echo "   • Send heartbeat:"
echo '     ["","2","","heartbeat",{}]'
echo
echo "🎉 Installation finished successfully!"