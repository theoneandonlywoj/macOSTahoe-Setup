#!/bin/zsh
# === Spotify Installer for macOS Tahoe (Zsh) ===
# Author: theoneandonlywoj
# Description:
#   Installs Spotify via Homebrew.
#   Run dock_cleanup.zsh after all apps are installed to configure the Dock.

echo "🎵 Spotify Installer (macOS Tahoe)"
echo "------------------------------------"

# === 1. Check for admin rights ===
if [[ $EUID -ne 0 ]]; then
  echo "⚠️  Some steps may require admin privileges."
  echo "   You might be asked for your password."
fi
echo

# === 2. Check for Homebrew ===
if command -v brew >/dev/null 2>&1; then
  echo "🍺 Homebrew detected."
  echo "📦 Installing Spotify via Homebrew Cask..."
  brew install --cask spotify
  if [[ $? -eq 0 ]]; then
    echo "✅ Spotify installed successfully via Homebrew!"
  else
    echo "❌ Failed to install Spotify via Homebrew."
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

# === 3. Verify installation ===
if [[ ! -d "/Applications/Spotify.app" ]]; then
  echo "❌ Spotify installation failed."
  exit 1
fi

echo
echo "🚀 Spotify installed at: /Applications/Spotify.app"
echo
echo "🎉 Spotify has been installed!"
echo "🎵 You can launch it anytime with: open -a Spotify"
echo "📌 Run dock_cleanup.zsh to add it to your Dock."
echo "------------------------------------"
