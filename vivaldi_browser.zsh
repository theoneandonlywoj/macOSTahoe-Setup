#!/bin/zsh
# === vivaldi_browser.zsh ===
# Purpose: Install Vivaldi browser on macOS Ventura and add to Dock after Slack
# Shell: Zsh (default on macOS Ventura)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting installation of Vivaldi browser on macOS Ventura..."
echo

# === Configuration ===
vivaldi_dmg_url="https://downloads.vivaldi.com/stable/Vivaldi.dmg"
vivaldi_dmg_tmp="/tmp/Vivaldi.dmg"
vivaldi_app="/Applications/Vivaldi.app"
dock_add="yes"                                             # set to "yes" to add to Dock
dock_after_app="Slack"                                     # Dock app after which Vivaldi should appear
echo "📌 Will download from: $vivaldi_dmg_url"
echo "📂 Target installation path: $vivaldi_app"
echo "🎯 Add to Dock?   $dock_add (after $dock_after_app)"
echo

# === 1. Check if Vivaldi is already installed ===
if [[ -d "$vivaldi_app" ]]; then
  echo "✅ Vivaldi is already installed at $vivaldi_app"
else
  # === 2. Download the DMG installer ===
  echo "📥 Downloading Vivaldi DMG..."
  curl -L -o "$vivaldi_dmg_tmp" "$vivaldi_dmg_url"
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to download Vivaldi DMG."
    exit 1
  fi

  # === 3. Mount DMG and install ===
  echo "💿 Mounting DMG installer..."
  mount_output=$(hdiutil attach "$vivaldi_dmg_tmp" -nobrowse 2>/dev/null)
  if [[ $? -eq 0 ]]; then
    volume_path=$(echo "$mount_output" | grep -o "/Volumes/[^$]*" | head -n1)
    echo "📁 Mounted at: $volume_path"

    # Locate Vivaldi.app inside the volume
    vivaldi_app_source=$(find "$volume_path" -maxdepth 1 -name "Vivaldi.app" -type d | head -n1)
    if [[ -n "$vivaldi_app_source" ]]; then
      echo "🧩 Installing Vivaldi from mounted volume..."
      cp -R "$vivaldi_app_source" /Applications/
      if [[ $? -ne 0 ]]; then
        echo "❌ Failed to copy Vivaldi.app into /Applications."
        hdiutil detach "$volume_path" -quiet
        rm -f "$vivaldi_dmg_tmp"
        exit 1
      fi
      echo "✅ Vivaldi installed into /Applications"
    else
      echo "❌ Could not find Vivaldi.app inside mounted volume."
      hdiutil detach "$volume_path" -quiet
      rm -f "$vivaldi_dmg_tmp"
      exit 1
    fi

    # === 4. Clean up — unmount and remove DMG ===
    echo "🧹 Cleaning up..."
    hdiutil detach "$volume_path" -quiet
    rm -f "$vivaldi_dmg_tmp"
    echo "✅ DMG unmounted and installer removed"
  else
    echo "❌ Failed to mount Vivaldi DMG."
    rm -f "$vivaldi_dmg_tmp"
    exit 1
  fi
fi

# === 5. Optionally add Vivaldi to Dock after Slack ===
if [[ "$dock_add" = "yes" ]]; then
  echo
  echo "🧭 Configuring Dock to include Vivaldi after $dock_after_app..."

  # Backup current Dock preferences
  defaults export com.apple.dock - > ~/Desktop/com.apple.dock.backup.vivaldi.plist 2>/dev/null
  echo "💾 Dock preference backup saved to ~/Desktop/com.apple.dock.backup.vivaldi.plist"

  # Build new Dock array
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

  # Clear existing Dock apps and rewrite
  defaults write com.apple.dock persistent-apps -array
  for app in "${new_dock[@]}"; do
    defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"
  done

  # Restart Dock
  echo "🔄 Restarting Dock..."
  killall Dock 2>/dev/null
  echo "✅ Dock updated"
fi

# === 6. Verification and wrap-up ===
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