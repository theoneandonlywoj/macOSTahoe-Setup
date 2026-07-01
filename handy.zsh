#!/bin/zsh
# === handy.zsh ===
# Purpose: Install Handy (handy.computer) — a free, open-source, offline
#          speech-to-text app — via Homebrew Cask on macOS
# Shell: Zsh (default)
# Author: theoneandonlywoj

echo "🚀 Starting Handy installation on macOS..."
echo

# === 0. Basic sanity checks ===

# macOS check
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ This script is intended for macOS only."
  exit 1
fi

# macOS version check (Handy requires macOS 13 Ventura or later)
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if [[ "$MACOS_MAJOR" -lt 13 ]]; then
  echo "❌ Handy requires macOS 13 (Ventura) or later. Detected: $(sw_vers -productVersion)"
  exit 1
fi
echo "✅ macOS $(sw_vers -productVersion) detected."

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "❌ Homebrew is not installed."
  echo "   Please install Homebrew first from: https://brew.sh"
  exit 1
fi
echo "✅ Homebrew detected."

# === 1. Install Handy via Homebrew Cask ===
echo
echo "📥 Installing Handy via Homebrew Cask..."
if brew list --cask handy >/dev/null 2>&1; then
  echo "ℹ️  Handy is already installed. Upgrading to latest..."
  brew upgrade --cask handy || {
    echo "⚠️  Failed to upgrade Handy. Continuing with existing version."
  }
else
  brew install --cask handy
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install Handy via Homebrew Cask."
    echo "   You can retry manually or grab a release from:"
    echo "   https://handy.computer  •  https://github.com/cjpais/Handy/releases"
    exit 1
  fi
fi

# === 2. Verification ===
echo
echo "🧪 Verifying Handy installation..."

if ! brew list --cask handy >/dev/null 2>&1; then
  echo "❌ Handy cask not found even after installation."
  exit 1
fi

APP_PATH="/Applications/Handy.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "⚠️  Handy.app was not found in /Applications."
  echo "   The cask installed, but the app bundle is in an unexpected location."
else
  handy_version=$(brew list --cask --versions handy 2>/dev/null | awk '{print $2}')
  echo "📌 Handy app: $APP_PATH"
  echo "📌 Handy version: ${handy_version:-unknown}"
  echo "✅ Handy setup complete!"
fi

# === 3. Wrap-up ===
echo
echo "💡 Next steps:"
echo "   • Launch Handy:            open -a Handy"
echo "   • On first launch, grant permissions when prompted:"
echo "       - Microphone   (System Settings → Privacy & Security → Microphone)"
echo "       - Accessibility (System Settings → Privacy & Security → Accessibility)"
echo "   • Pick a speech-to-text model to download (runs 100% offline):"
echo "       - Parakeet V3 → fast & accurate for English / European languages"
echo "       - Whisper     → best for multilingual support (99+ languages)"
echo "   • Hold your shortcut, speak, and Handy pastes the text at your cursor."
echo "   • Docs: https://handy.computer/docs"
echo
echo "🎉 Installation finished successfully!"
