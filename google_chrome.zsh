#!/bin/zsh
# === Google Chrome Installer for macOS Tahoe (Zsh) ===
# Author: theoneandonlywoj
# Description:
#   Installs Google Chrome via Homebrew or .dmg fallback.
#   Run dock_cleanup.zsh after all apps are installed to configure the Dock.

echo "🌐 Google Chrome Installer (macOS Tahoe)"
echo "-----------------------------------------"

# === 1. Check for admin rights ===
if [[ $EUID -ne 0 ]]; then
  echo "⚠️  Some steps may require admin privileges."
  echo "   You might be asked for your password."
fi
echo

# === 2. Check for Homebrew ===
if command -v brew >/dev/null 2>&1; then
  echo "🍺 Homebrew detected."
  echo "📦 Installing Google Chrome via Homebrew Cask..."
  brew install --cask google-chrome
  if [[ $? -eq 0 ]]; then
    echo "✅ Google Chrome installed successfully via Homebrew!"
  else
    echo "❌ Failed to install Chrome via Homebrew."
    exit 1
  fi
else
  echo "⚠️  Homebrew not found. Installing Google Chrome manually..."
  echo "⬇️  Downloading Chrome .dmg..."
  tmp_dir="/tmp/chrome_install"
  mkdir -p "$tmp_dir"
  dmg_path="$tmp_dir/GoogleChrome.dmg"

  curl -L "https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg" -o "$dmg_path"
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to download Chrome."
    exit 1
  fi

  echo "💿 Mounting GoogleChrome.dmg..."
  hdiutil attach "$dmg_path" -nobrowse -quiet
  sleep 2

  if [[ -d "/Volumes/Google Chrome/Google Chrome.app" ]]; then
    echo "📂 Copying Google Chrome.app to /Applications..."
    cp -R "/Volumes/Google Chrome/Google Chrome.app" /Applications/
    echo "✅ Chrome installed successfully in /Applications."
  else
    echo "❌ Google Chrome.app not found in DMG."
  fi

  echo "🧹 Cleaning up..."
  hdiutil detach "/Volumes/Google Chrome" -quiet
  rm -rf "$tmp_dir"
fi

# === 3. Verify installation ===
if [[ ! -d "/Applications/Google Chrome.app" ]]; then
  echo "❌ Chrome installation failed."
  exit 1
fi

echo
echo "🚀 Chrome installed at: /Applications/Google Chrome.app"
echo
echo "🎉 Google Chrome has been installed!"
echo "💫 You can launch it anytime with: open -a 'Google Chrome'"
echo "📌 Run dock_cleanup.zsh to add it to your Dock."
echo "-----------------------------------------"