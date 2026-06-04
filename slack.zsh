#!/bin/zsh
# === Slack Installer + Dock Setup for macOS Tahoe (Zsh) ===
# Author: theoneandonlywoj
# Description:
#   Installs Slack via Homebrew or .dmg fallback,
#   adds Slack to the Dock one position before Notes,
#   and restarts the Dock to apply changes.

echo "💬 Slack Installer + Dock Setup (macOS Tahoe)"
echo "-----------------------------------------------"

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

# === 4. Add Slack to Dock ===
echo
echo "🧭 Adding Slack to Dock one position before Notes..."

slack_path="/Applications/Slack.app"
notes_name="Notes"

# --- Try using dockutil (preferred) ---
if command -v dockutil >/dev/null 2>&1; then
  echo "⚙️  Using dockutil to manage Dock..."

  # Remove any existing Slack icon
  dockutil --remove "Slack" --no-restart >/dev/null 2>&1

  # Add Slack before Notes if Notes exists
  if dockutil --find "$notes_name" >/dev/null 2>&1; then
    dockutil --add "$slack_path" --before "$notes_name" --no-restart
  else
    dockutil --add "$slack_path" --no-restart
    echo "ℹ️  Notes not found in Dock. Added Slack at the end."
  fi

else
  # --- Fallback if dockutil isn't installed ---
  echo "⚠️  dockutil not found. Using fallback method."
  echo "   (You can install dockutil with: brew install dockutil)"

  # Fallback adds Slack to the end of the Dock
  defaults write com.apple.dock persistent-apps -array-add "<dict>
    <key>tile-data</key>
    <dict>
      <key>file-data</key>
      <dict>
        <key>_CFURLString</key>
        <string>$slack_path</string>
        <key>_CFURLStringType</key>
        <integer>0</integer>
      </dict>
    </dict>
  </dict>"
fi

# === 5. Restart Dock to apply changes ===
echo "🔄 Restarting Dock..."
killall Dock 2>/dev/null
sleep 2

echo
echo "🎉 Slack has been installed and added to your Dock!"
echo "💬 It’s placed just before Notes (if present)."
echo "🚀 You can launch it anytime with: open -a Slack"
echo "--------------------------------------------------"

