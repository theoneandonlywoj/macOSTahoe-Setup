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
echo "   • Configure AI providers: opencode (first run will prompt you)"
echo "   • Run dock_cleanup.zsh to add OpenCode to your Dock"
echo
echo "🚀 Starting the OpenCode CLI:"
echo
echo "   • Start the TUI in any project:"
echo "       cd ~/my-project && opencode"
echo "       opencode /path/to/project"
echo
echo "   • Choose a model (provider/model):"
echo "       opencode --model anthropic/claude-sonnet-4"
echo "       opencode --model openai/gpt-5"
echo "       opencode --model deepseek/deepseek-chat"
echo "       opencode -m <provider/model>              # short flag"
echo "     List available models: opencode models"
echo
echo "   • Pick a model variant (reasoning effort):"
echo "       opencode run \"...\" --variant high        # more reasoning"
echo "       opencode run \"...\" --variant low         # faster/cheaper"
echo "     In the TUI, press ctrl+t to cycle variants for the current model"
echo
echo "   • Choose a mode — Build (all tools, default) or Plan (read-only analysis):"
echo "       opencode --agent build                    # full dev work"
echo "       opencode --agent plan                     # analyze without changing files"
echo "     In the TUI, press Tab to switch between Build and Plan"
echo
echo "   • Run a one-off prompt without the TUI:"
echo "       opencode run \"Explain how closures work in Go\""
echo "       opencode run --model openai/gpt-5 \"Review this PR\"" 
echo "       opencode run --agent plan --model anthropic/claude-haiku \"Outline a migration plan\""
echo
echo "   • Work with sessions:"
echo "       opencode --continue                        # resume last session"
echo "       opencode --session <id>                    # continue a specific session"
echo "       opencode --session <id> --fork             # fork a session"
echo "       opencode session list                      # list sessions"
echo
echo "   • Other useful options:"
echo "       opencode --auto                            # auto-approve permissions"
echo "       opencode --port 4096 --hostname 0.0.0.0    # web/mobile access"
echo "       opencode auth login                        # add a provider/API key"
echo "       opencode upgrade                           # update to latest version"
echo
echo "   • Docs: https://opencode.ai/docs"
echo "   • CLI reference: https://opencode.ai/docs/cli"