#!/bin/zsh
# === vscode_ide.zsh ===
# Purpose: Install Visual Studio Code on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting installation of Visual Studio Code on macOS Tahoe..."
echo

# === Configuration ===
vscode_zip_url="https://update.code.visualstudio.com/latest/darwin-universal/stable"
vscode_zip_tmp="/tmp/VSCode.zip"
vscode_app="/Applications/Visual Studio Code.app"
echo "📌 Will download from: $vscode_zip_url"
echo "📂 Target installation path: $vscode_app"
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

# === 5. Verification and wrap-up ===
echo
echo "🧪 Verifying installation..."
if [[ -d "$vscode_app" ]]; then
  echo "✅ Visual Studio Code installation confirmed at $vscode_app"
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
echo "   • Run dock_cleanup.zsh to add VSCode to your Dock"
echo "   • Enjoy your coding environment!"