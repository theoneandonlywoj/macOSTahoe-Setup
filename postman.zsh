#!/bin/zsh
# === Postman Installer + Dock Setup for macOS Ventura (Zsh) ===
# Author: theoneandonlywoj
# Description:
#   Installs Postman via Homebrew, adds it to the Dock
#   right after Calendar, and refreshes the Dock.

echo "📮 Postman Installer + Dock Setup (macOS Ventura)"
echo "------------------------------------------------------"

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

# === 4. Add Postman to Dock ===
echo
echo "🧭 Adding Postman to Dock..."

postman_path="/Applications/Postman.app"
calendar_path="/System/Applications/Calendar.app"

# Method 1: Use dockutil if available (best)
if command -v dockutil >/dev/null 2>&1; then
  echo "⚙️  Using dockutil to manage Dock..."
  
  # Remove existing Postman icon if present
  dockutil --remove "Postman" --no-restart >/dev/null 2>&1

  # Insert Postman after Calendar if possible
  if dockutil --find "Calendar" >/dev/null 2>&1; then
    dockutil --add "$postman_path" --after "Calendar" --no-restart
  else
    dockutil --add "$postman_path" --no-restart
  fi

else
  # Method 2: Fallback using defaults (if dockutil not installed)
  echo "⚠️  dockutil not found. Using built-in Dock modification..."
  echo "   (You can install dockutil with: brew install dockutil)"

  # Read Dock entries
  defaults write com.apple.dock persistent-apps -array-add "<dict>
    <key>tile-data</key>
    <dict>
      <key>file-data</key>
      <dict>
        <key>_CFURLString</key>
        <string>$postman_path</string>
        <key>_CFURLStringType</key>
        <integer>0</integer>
      </dict>
    </dict>
  </dict>"
fi

# === 5. Restart Dock to apply changes ===
echo "🔄 Restarting Dock to apply changes..."
killall Dock 2>/dev/null
sleep 2

echo
echo "🎉 Postman has been installed and added to your Dock!"
echo "💫 You can launch it anytime with: open -a 'Postman'"
echo "-----------------------------------------------------------"
