#!/bin/zsh
# === cursor_ide.zsh ===
# Purpose: Install Cursor AI code editor on macOS Tahoe and add to Dock after Slack
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting installation of Cursor AI (the vibe-coding editor) on macOS Tahoe..."
echo

# === Configuration ===
cursor_app="/Applications/Cursor.app"
dock_add="yes"
dock_after_app="Slack"
echo "📂 Target installation path: $cursor_app"
echo "🎯 Add to Dock?   $dock_add (after $dock_after_app)"
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

# === 3. Optionally add Cursor to Dock after Slack ===
if [[ "$dock_add" = "yes" ]]; then
  echo
  echo "🧭 Configuring Dock to include Cursor after $dock_after_app..."

  if command -v dockutil >/dev/null 2>&1; then
    echo "⚙️  Using dockutil to manage Dock..."

    dockutil --remove "Cursor" --no-restart >/dev/null 2>&1

    if dockutil --find "$dock_after_app" >/dev/null 2>&1; then
      dockutil --add "$cursor_app" --after "$dock_after_app" --no-restart
    else
      dockutil --add "$cursor_app" --no-restart
      echo "ℹ️  $dock_after_app not found in Dock. Added Cursor at the end."
    fi
  else
    echo "⚠️  dockutil not found. Using built-in Dock modification..."
    echo "   (You can install dockutil with: brew install dockutil)"

    defaults export com.apple.dock - > ~/Desktop/com.apple.dock.backup.cursor.plist 2>/dev/null
    echo "💾 Dock preference backup saved to ~/Desktop/com.apple.dock.backup.cursor.plist"

    dock_apps=($(defaults read com.apple.dock persistent-apps | grep _CFURLString | awk -F'"' '{print $2}'))
    new_dock=()
    inserted=false

    for app_path in "${dock_apps[@]}"; do
      new_dock+=("$app_path")
      if [[ "$app_path" == *"$dock_after_app.app"* && "$inserted" = false ]]; then
        new_dock+=("$cursor_app")
        inserted=true
      fi
    done

    if [[ "$inserted" = false ]]; then
      echo "⚠️ Target app ($dock_after_app) not found in Dock. Adding Cursor at the end."
      new_dock+=("$cursor_app")
    fi

    defaults write com.apple.dock persistent-apps -array
    for app in "${new_dock[@]}"; do
      defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"
    done
  fi

  echo "🔄 Restarting Dock..."
  killall Dock 2>/dev/null
  echo "✅ Dock updated"
fi

# === 4. Verification and wrap-up ===
echo
echo "🧪 Verifying installation..."
if [[ -d "$cursor_app" ]]; then
  echo "✅ Cursor installation confirmed at $cursor_app"
  if [[ "$dock_add" = "yes" ]]; then
    echo "📍 Cursor should now appear in your Dock after $dock_after_app."
  fi
else
  echo "❌ Cursor installation failed. Please check the error logs above."
  exit 1
fi

echo
echo "🎉 Cursor AI installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch Cursor via Launchpad or Spotlight (⌘ Space → 'Cursor')"
echo "   • Enjoy your AI-powered coding environment!"