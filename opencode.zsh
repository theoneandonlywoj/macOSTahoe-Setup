#!/bin/zsh
# === opencode.zsh ===
# Purpose: Install OpenCode (open-source AI coding agent) CLI and Desktop on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj (style inspired)

echo "🚀 Starting installation of OpenCode (open-source AI coding agent) on macOS Tahoe..."
echo

# === Configuration ===
install_cli="yes"
install_desktop="yes"
opencode_app="/Applications/OpenCode.app"

echo "📌 CLI install?        $install_cli"
echo "📌 Desktop install?    $install_desktop"
echo "📂 Target path:        $opencode_app"
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
    if ! command -v brew >/dev/null 2>&1; then
      echo "⚙️  Homebrew not found. Installing..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [[ -d "/opt/homebrew/bin" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
      echo "✅ Homebrew installed."
    fi
    echo "📥 Installing OpenCode Desktop via Homebrew cask..."
    brew install --cask opencode-desktop
    if [[ $? -ne 0 ]]; then
      echo "❌ Homebrew cask install failed."
      exit 1
    fi
    echo "✅ OpenCode Desktop installed via Homebrew"
  fi
  echo
fi

# === 3. Verification and wrap-up ===
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
echo "   • Run dock_cleanup.zsh to add OpenCode to your Dock"
echo "   • Docs: https://opencode.ai/docs"