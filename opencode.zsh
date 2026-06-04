#!/bin/zsh
# === opencode.zsh ===
# Purpose: Install OpenCode (open-source AI coding agent) CLI and Desktop on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting installation of OpenCode (open-source AI coding agent) on macOS Tahoe..."
echo

# === Configuration ===
install_cli="yes"                                               # set to "yes" to install the CLI
install_desktop="yes"                                           # set to "yes" to install the Desktop app
dock_add="yes"                                                  # set to "yes" to add to Dock after target app
dock_after_app="Cursor"                                         # Dock app after which OpenCode should appear
opencode_app="/Applications/OpenCode.app"
opencode_desktop_dmg_url_aarch64="https://opencode.ai/download/stable/darwin-aarch64-dmg"
opencode_desktop_dmg_url_x64="https://opencode.ai/download/stable/darwin-x64-dmg"
opencode_dmg_tmp="/tmp/OpenCode.dmg"

echo "📌 CLI install?        $install_cli"
echo "📌 Desktop install?    $install_desktop"
echo "📂 Target path:        $opencode_app"
if [[ "$install_desktop" = "yes" ]]; then
  arch=$(uname -m)
  if [[ "$arch" = "arm64" ]]; then
    echo "💻 Architecture:       Apple Silicon (arm64)"
    echo "🔗 Download URL:      $opencode_desktop_dmg_url_aarch64"
  else
    echo "💻 Architecture:       Intel (x86_64)"
    echo "🔗 Download URL:      $opencode_desktop_dmg_url_x64"
  fi
fi
echo "🎯 Add to Dock?        $dock_add (after $dock_after_app)"
echo

# === 1. Install OpenCode CLI ===
if [[ "$install_cli" = "yes" ]]; then
  echo "===== CLI Installation ====="
  echo
  if command -v opencode >/dev/null 2>&1; then
    echo "✅ OpenCode CLI is already installed: $(opencode --version 2>/dev/null || echo 'version unknown')"
  else
    echo "📥 Installing OpenCode CLI via official install script..."
    curl -fsSL https://opencode.ai/install | bash
    if [[ $? -ne 0 ]]; then
      echo "⚠️  CLI install script failed. Trying Homebrew fallback..."
      if ! command -v brew >/dev/null 2>&1; then
        echo "⚙️  Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -d "/opt/homebrew/bin" ]]; then
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
          eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        echo "✅ Homebrew installed."
      fi
      brew install anomalyco/tap/opencode
    fi

    if command -v opencode >/dev/null 2>&1; then
      echo "✅ OpenCode CLI installed successfully: $(opencode --version 2>/dev/null || echo 'version unknown')"
    else
      echo "⚠️  OpenCode CLI not found in PATH. You may need to restart your terminal."
    fi
  fi
  echo
fi

# === 2. Install OpenCode Desktop ===
if [[ "$install_desktop" = "yes" ]]; then
  echo "===== Desktop App Installation ====="
  echo
  if [[ -d "$opencode_app" ]]; then
    echo "✅ OpenCode Desktop is already installed at $opencode_app"
  else
    # Determine download URL based on architecture
    arch=$(uname -m)
    if [[ "$arch" = "arm64" ]]; then
      dmg_url="$opencode_desktop_dmg_url_aarch64"
    else
      dmg_url="$opencode_desktop_dmg_url_x64"
    fi

    echo "📥 Downloading OpenCode Desktop DMG..."
    curl -L -o "$opencode_dmg_tmp" "$dmg_url"
    if [[ $? -ne 0 ]]; then
      echo "❌ Failed to download OpenCode Desktop DMG."
      exit 1
    fi

    echo "💿 Mounting or extracting installer..."

    mount_output=$(hdiutil attach "$opencode_dmg_tmp" -nobrowse 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      volume_path=$(echo "$mount_output" | grep -o "/Volumes/[^[:space:]]*" | head -n1)

      if [[ -d "$volume_path/OpenCode.app" ]]; then
        echo "📁 Installing OpenCode from mounted volume: $volume_path"
        cp -R "$volume_path/OpenCode.app" /Applications/
        echo "✅ OpenCode Desktop installed into /Applications"
      else
        echo "⚠️  Could not find OpenCode.app inside mounted volume. Checking for ZIP fallback..."
        hdiutil detach "$volume_path" -quiet
        unzip -q "$opencode_dmg_tmp" -d /tmp/opencode_extract
        if [[ -d /tmp/opencode_extract/OpenCode.app ]]; then
          echo "📦 Copying OpenCode.app to /Applications..."
          cp -R /tmp/opencode_extract/OpenCode.app /Applications/
          echo "✅ OpenCode Desktop installed into /Applications"
        else
          echo "❌ OpenCode.app not found in the archive."
          rm -rf /tmp/opencode_extract "$opencode_dmg_tmp"
          exit 1
        fi
        rm -rf /tmp/opencode_extract
      fi

      echo "🧹 Cleaning up..."
      hdiutil detach "$volume_path" -quiet 2>/dev/null
      rm -f "$opencode_dmg_tmp"
      echo "✅ DMG unmounted and removed"
    else
      echo "⚠️  DMG mount failed — treating file as ZIP or direct app bundle..."
      mkdir -p /tmp/opencode_extract
      unzip -q "$opencode_dmg_tmp" -d /tmp/opencode_extract
      if [[ -d /tmp/opencode_extract/OpenCode.app ]]; then
        echo "📦 Copying OpenCode.app to /Applications..."
        cp -R /tmp/opencode_extract/OpenCode.app /Applications/
        echo "✅ OpenCode Desktop installed into /Applications"
      else
        echo "❌ Could not find OpenCode.app inside the downloaded archive."
        rm -rf /tmp/opencode_extract "$opencode_dmg_tmp"
        exit 1
      fi
      rm -rf /tmp/opencode_extract
      rm -f "$opencode_dmg_tmp"
      echo "✅ OpenCode Desktop installed and temporary files removed"
    fi
  fi
  echo
fi

# === 3. Optionally add OpenCode to Dock ===
if [[ "$dock_add" = "yes" && -d "$opencode_app" ]]; then
  echo "===== Dock Configuration ====="
  echo
  echo "🧭 Configuring Dock to include OpenCode after $dock_after_app..."

  defaults export com.apple.dock - > ~/Desktop/com.apple.dock.backup.opencode.plist 2>/dev/null
  echo "💾 Dock preference backup saved to ~/Desktop/com.apple.dock.backup.opencode.plist"

  dock_apps=($(defaults read com.apple.dock persistent-apps | grep _CFURLString | awk -F'"' '{print $2}'))
  new_dock=()
  inserted=false

  for app_path in "${dock_apps[@]}"; do
    new_dock+=("$app_path")
    if [[ "$app_path" == *"$dock_after_app.app"* && "$inserted" = false ]]; then
      new_dock+=("$opencode_app")
      inserted=true
    fi
  done

  if [[ "$inserted" = false ]]; then
    echo "⚠️  Target app ($dock_after_app) not found in Dock. Adding OpenCode at the end."
    new_dock+=("$opencode_app")
  fi

  defaults write com.apple.dock persistent-apps -array
  for app in "${new_dock[@]}"; do
    defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"
  done

  echo "🔄 Restarting Dock..."
  killall Dock 2>/dev/null
  echo "✅ Dock updated"
  echo
fi

# === 4. Verification and wrap-up ===
echo "🧪 Verifying installation..."
echo

cli_ok=false
desktop_ok=false

if command -v opencode >/dev/null 2>&1; then
  echo "✅ OpenCode CLI: $(opencode --version 2>/dev/null || echo 'installed')"
  cli_ok=true
else
  echo "⚠️  OpenCode CLI not found in PATH. Try restarting your terminal."
fi

if [[ -d "$opencode_app" ]]; then
  echo "✅ OpenCode Desktop: installed at $opencode_app"
  desktop_ok=true
else
  echo "⚠️  OpenCode Desktop not found at $opencode_app"
fi

echo
if [[ "$cli_ok" = true || "$desktop_ok" = true ]]; then
  echo "🎉 OpenCode installation complete!"
else
  echo "❌ OpenCode installation failed. Please check the error logs above."
  exit 1
fi

echo
echo "💡 Next steps:"
echo "   • Launch OpenCode Desktop via Spotlight (⌘ Space → 'OpenCode')"
echo "   • Run OpenCode CLI in any project: cd ~/my-project && opencode"
echo "   • Configure AI providers: opencode (first run will prompt you)"
echo "   • Docs: https://opencode.ai/docs"
echo