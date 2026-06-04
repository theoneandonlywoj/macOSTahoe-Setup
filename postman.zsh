#!/bin/zsh
# === Postman Installer for macOS Tahoe (Zsh) ===
# Author: theoneandonlywoj
# Description:
#   Installs Postman via Homebrew.
#   Run dock_cleanup.zsh after all apps are installed to configure the Dock.

echo "📮 Postman Installer (macOS Tahoe)"
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
  echo "📦 Installing Postman via Homebrew Cask..."
  brew install --cask postman
  if [[ $? -eq 0 ]]; then
    echo "✅ Postman installed successfully via Homebrew!"
  else
    echo "❌ Failed to install Postman via Homebrew."
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
if [[ ! -d "/Applications/Postman.app" ]]; then
  echo "❌ Postman installation failed."
  exit 1
fi

echo
echo "🚀 Postman installed at: /Applications/Postman.app"
echo
echo "🎉 Postman has been installed!"
echo "💫 You can launch it anytime with: open -a 'Postman'"
echo "📌 Run dock_cleanup.zsh to add it to your Dock."
echo "------------------------------------"