#!/bin/zsh
# === Slack Installer for macOS Tahoe (Zsh) ===
# Author: theoneandonlywoj
# Description:
#   Installs Slack via Homebrew or .dmg fallback.
#   Run dock_cleanup.zsh after all apps are installed to configure the Dock.

echo "💬 Slack Installer (macOS Tahoe)"
echo "---------------------------------"

# === 1. Check for admin rights ===
if [[ $EUID -ne 0 ]]; then
  echo "⚠️  Some steps may require admin privileges."
  echo "   You might be asked for your password."
fi
echo

# === 2. Check for Homebrew ===
if command -v brew >/dev/null 2>&1; then
  echo "🍺 Homebrew detected."
  echo "📦 Installing Slack via Homebrew Cask..."
  brew install --cask slack
  if [[ $? -eq 0 ]]; then
    echo "✅ Slack installed successfully via Homebrew!"
  else
    echo "❌ Failed to install Slack via Homebrew."
    exit 1
  fi
else
  echo "⚠️  Homebrew not found. Installing Slack manually..."
  echo "⬇️  Downloading Slack .dmg..."
  tmp_dir="/tmp/slack_install"
  mkdir -p "$tmp_dir"
  dmg_path="$tmp_dir/Slack.dmg"

  curl -L "https://slack.com/ssb/download-osx" -o "$dmg_path"
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to download Slack."
    exit 1
  fi

  echo "💿 Mounting Slack.dmg..."
  hdiutil attach "$dmg_path" -nobrowse -quiet
  sleep 2

  if [[ -d "/Volumes/Slack/Slack.app" ]]; then
    echo "📂 Copying Slack.app to /Applications..."
    cp -R "/Volumes/Slack/Slack.app" /Applications/
    echo "✅ Slack installed successfully in /Applications."
  else
    echo "❌ Slack.app not found in DMG."
  fi

  echo "🧹 Cleaning up..."
  hdiutil detach "/Volumes/Slack" -quiet
  rm -rf "$tmp_dir"
fi

# === 3. Verify installation ===
if [[ ! -d "/Applications/Slack.app" ]]; then
  echo "❌ Slack installation failed."
  exit 1
fi

echo
echo "🚀 Slack installed at: /Applications/Slack.app"
echo
echo "🎉 Slack has been installed!"
echo "💬 You can launch it anytime with: open -a Slack"
echo "📌 Run dock_cleanup.zsh to add it to your Dock."
echo "---------------------------------"