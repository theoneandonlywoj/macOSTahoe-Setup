#!/bin/zsh
# === vivaldi_browser.zsh ===
# Purpose: Install Vivaldi browser on macOS Tahoe and add to Dock after Slack
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting installation of Vivaldi browser on macOS Tahoe..."
echo

# === Configuration ===
vivaldi_app="/Applications/Vivaldi.app"
dock_add="yes"
dock_after_app="Slack"
echo "📂 Target installation path: $vivaldi_app"
echo "🎯 Add to Dock?   $dock_add (after $dock_after_app)"
echo

# === 1. Install Vivaldi ===
if command -v brew >/dev/null 2>&1; then
  echo "🍺 Homebrew detected."
  echo "📦 Installing Vivaldi via Homebrew Cask..."
  brew install --cask vivaldi
  if [[ $? -eq 0 ]]; then
    echo "✅ Vivaldi installed successfully via Homebrew!"
  else
    echo "❌ Failed to install Vivaldi via Homebrew."
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
if [[ ! -d "$vivaldi_app" ]]; then
  echo "❌ Vivaldi installation failed."
  exit 1
fi

echo
echo "🚀 Vivaldi installed at: $vivaldi_app"

# === 3. Optionally add Vivaldi to Dock after Slack ===
if [[ "$dock_add" = "yes" ]]; then
  echo
  echo "🧭 Configuring Dock to include Vivaldi after $dock_after_app..."

  if command -v dockutil >/dev/null 2>&1; then
    echo "⚙️  Using dockutil to manage Dock..."

    dockutil --remove "Vivaldi" --no-restart >/dev/null 2>&1

    if dockutil --find "$dock_after_app" >/dev/null 2>&1; then
      dockutil --add "$vivaldi_app" --after "$dock_after_app" --no-restart
    else
      dockutil --add "$vivaldi_app" --no-restart
      echo "ℹ️  $dock_after_app not found in Dock. Added Vivaldi at the end."
    fi
  else
    echo "⚠️  dockutil not found. Using built-in Dock modification..."
    echo "   (You can install dockutil with: brew install dockutil)"

    defaults export com.apple.dock - > ~/Desktop/com.apple.dock.backup.vivaldi.plist 2>/dev/null
    echo "💾 Dock preference backup saved to ~/Desktop/com.apple.dock.backup.vivaldi.plist"

    dock_apps=($(defaults read com.apple.dock persistent-apps | grep _CFURLString | awk -F'"' '{print $2}'))
    new_dock=()
    inserted=false

    for app_path in "${dock_apps[@]}"; do
      new_dock+=("$app_path")
      if [[ "$app_path" == *"$dock_after_app.app"* && "$inserted" = false ]]; then
        new_dock+=("$vivaldi_app")
        inserted=true
      fi
    done

    if [[ "$inserted" = false ]]; then
      echo "⚠️ Target app ($dock_after_app) not found in Dock. Adding Vivaldi at the end."
      new_dock+=("$vivaldi_app")
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
if [[ -d "$vivaldi_app" ]]; then
  echo "✅ Vivaldi installation confirmed at $vivaldi_app"
  if [[ "$dock_add" = "yes" ]]; then
    echo "📍 Vivaldi should now appear in your Dock after $dock_after_app."
  fi
else
  echo "❌ Vivaldi installation failed. Please check the error logs above."
  exit 1
fi

echo
echo "🎉 Vivaldi browser installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch Vivaldi via Launchpad or Spotlight (⌘ Space → 'Vivaldi')"
echo "   • Set Vivaldi as your default browser in System Settings if desired"
echo "   • Enjoy your privacy-first browsing experience!"