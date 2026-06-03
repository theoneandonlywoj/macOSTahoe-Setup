#!/bin/zsh
# === vscode_ide.zsh ===
# Purpose: Install Visual Studio Code on macOS Ventura and add to Dock after Slack
# Shell: Zsh (default on macOS Ventura)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting installation of Visual Studio Code on macOS Ventura..."
echo

# === Configuration ===
vscode_zip_url="https://update.code.visualstudio.com/latest/darwin-universal/stable"
vscode_zip_tmp="/tmp/VSCode.zip"
vscode_app="/Applications/Visual Studio Code.app"
dock_add="yes"                                             # set to "yes" to add to Dock
dock_after_app="Slack"                                     # Dock app after which VSCode should appear
echo "📌 Will download from: $vscode_zip_url"
echo "📂 Target installation path: $vscode_app"
echo "🎯 Add to Dock?   $dock_add (after $dock_after_app)"
echo

# === 1. Check if VSCode is already installed ===
if [[ -d "$vscode_app" ]]; then
  echo "✅ Visual Studio Code is already installed at $vscode_app"
else
  # === 2. Download the ZIP installer ===
  echo "📥 Downloading VSCode ZIP..."
  curl -L -o "$vscode_zip_tmp" "$vscode_zip_url"
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to download VSCode ZIP."
    exit 1
  fi

  # === 3. Extract and install ===
  echo "📦 Extracting VSCode ZIP..."
  mkdir -p /tmp/vscode_extract
  unzip -q "$vscode_zip_tmp" -d /tmp/vscode_extract
  if [[ -d "/tmp/vscode_extract/Visual Studio Code.app" ]]; then
    echo "📁 Copying Visual Studio Code.app to /Applications..."
    cp -R "/tmp/vscode_extract/Visual Studio Code.app" /Applications/
    echo "✅ Visual Studio Code installed into /Applications"
  else
    echo "❌ Could not find Visual Studio Code.app inside the downloaded archive."
    rm -rf /tmp/vscode_extract "$vscode_zip_tmp"
    exit 1
  fi

  # === 4. Clean up installer ===
  echo "🧹 Cleaning up..."
  rm -rf /tmp/vscode_extract
  rm -f "$vscode_zip_tmp"
  echo "✅ Temporary files removed"
fi

# === 5. Optionally add VSCode to Dock after Slack ===
if [[ "$dock_add" = "yes" ]]; then
  echo
  echo "🧭 Configuring Dock to include Visual Studio Code after $dock_after_app..."

  # Backup current Dock preferences
  defaults export com.apple.dock - > ~/Desktop/com.apple.dock.backup.vscode.plist 2>/dev/null
  echo "💾 Dock preference backup saved to ~/Desktop/com.apple.dock.backup.vscode.plist"

  # Build new Dock array
  dock_apps=($(defaults read com.apple.dock persistent-apps | grep _CFURLString | awk -F'"' '{print $2}'))
  new_dock=()
  inserted=false

  for app_path in "${dock_apps[@]}"; do
    new_dock+=("$app_path")
    if [[ "$app_path" == *"$dock_after_app.app"* && "$inserted" = false ]]; then
      new_dock+=("$vscode_app")
      inserted=true
    fi
  done

  if [[ "$inserted" = false ]]; then
    echo "⚠️ Target app ($dock_after_app) not found in Dock. Adding Visual Studio Code at the end."
    new_dock+=("$vscode_app")
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
if [[ -d "$vscode_app" ]]; then
  echo "✅ Visual Studio Code installation confirmed at $vscode_app"
  if [[ "$dock_add" = "yes" ]]; then
    echo "📍 Visual Studio Code should now appear in your Dock after $dock_after_app."
  fi
else
  echo "❌ Visual Studio Code installation failed. Please check the error logs above."
  exit 1
fi

echo
echo "🎉 Visual Studio Code installation complete!"
echo
echo "💡 Next steps:"
echo "   • Launch VSCode via Launchpad or Spotlight (⌘ Space → 'Visual Studio Code')"
echo "   • Install the 'code' shell command: open VSCode → ⌘⇧P → 'Shell Command: Install code command in PATH'"
echo "   • Enjoy your coding environment!"