#!/bin/zsh
# === linear_cli.zsh ===
# Purpose: Install or update the Linear CLI (token-efficient, agentic ticket tool) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting Linear CLI installation/update on macOS Tahoe..."
echo

# === Configuration ===
linear_bin="linear"
linear_brew_pkg="linear-cli"
linear_tap="joa23/linear-cli"

echo "🔗 Binary:             $linear_bin"
echo "📦 Homebrew package:   $linear_brew_pkg"
echo

# === 1. Check if Linear CLI is already installed ===
if command -v "$linear_bin" >/dev/null 2>&1; then
  current_version=$("$linear_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Linear CLI is already installed (version: $current_version)"
  echo
  echo "🔄 Updating Linear CLI via Homebrew..."
  brew upgrade "$linear_brew_pkg"
  if [[ $? -ne 0 ]]; then
    echo "ℹ️  Linear CLI may already be at the latest version."
  fi

  updated_version=$("$linear_bin" --version 2>/dev/null || echo "unknown")
  echo
  echo "📌 Linear CLI version: $updated_version"
  echo "✅ Linear CLI update complete!"
  echo
  echo "🎉 Linear CLI setup complete!"
  echo
  echo "💡 Next steps:"
  echo "   • See the full setup and usage guide below (run this script on a fresh install)."
  exit 0
fi

# === 2. Ensure Homebrew is installed ===
if ! command -v brew >/dev/null 2>&1; then
  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -d "/opt/homebrew/bin" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed."
  echo
fi

# === 3. Install Linear CLI via Homebrew tap ===
echo "📥 Installing Linear CLI via Homebrew tap ($linear_tap)..."
brew tap "$linear_tap" https://github.com/joa23/linear-cli
if [[ $? -ne 0 ]]; then
  echo "❌ Homebrew tap failed."
  echo "⚠️  Try running manually: brew tap $linear_tap https://github.com/joa23/linear-cli"
  exit 1
fi

install_output=$(brew install "$linear_brew_pkg" 2>&1)
install_status=$?

if [[ $install_status -ne 0 ]]; then
  if echo "$install_output" | grep -qi "untrusted tap"; then
    echo "⚠️  Homebrew refused to install from the untrusted tap '$linear_tap'."
    echo
    read -r "trust_choice?🤔 Do you want to trust this tap and continue? (Y/n) "
    trust_choice="${trust_choice:-y}"
    if [[ "$trust_choice" == "y" || "$trust_choice" == "Y" ]]; then
      echo "🛡️  Trusting tap '$linear_tap'..."
      brew trust "$linear_tap"
      if [[ $? -ne 0 ]]; then
        echo "❌ Failed to trust tap '$linear_tap'."
        echo "⚠️  Try running manually: brew trust $linear_tap"
        exit 1
      fi
      echo
      echo "📥 Retrying Linear CLI install..."
      brew install "$linear_brew_pkg"
      if [[ $? -ne 0 ]]; then
        echo "❌ Homebrew install failed."
        echo "⚠️  Try running manually: brew install $linear_brew_pkg"
        exit 1
      fi
    else
      echo "ℹ️  Skipping install. Tap is trusted, so you can retry later with:"
      echo "   brew trust $linear_tap"
      echo "   brew install $linear_brew_pkg"
      exit 0
    fi
  else
    echo "❌ Homebrew install failed."
    echo "⚠️  Try running manually: brew install $linear_brew_pkg"
    exit 1
  fi
fi
echo "✅ Linear CLI installed via Homebrew"
echo

# === 4. Verify installation ===
echo "🧪 Verifying installation..."
echo

if command -v "$linear_bin" >/dev/null 2>&1; then
  installed_version=$("$linear_bin" --version 2>/dev/null || echo "unknown")
  echo "✅ Linear CLI: installed (version: $installed_version)"
else
  echo "⚠️  Linear CLI not found in PATH."
  echo "   It may have installed elsewhere. Check with: which linear"
  exit 1
fi

# === 5. Wrap-up ===
echo
echo "🎉 Linear CLI installation complete!"
echo
echo "💡 Next steps:"
echo
echo "🔐 Auth & setup:"
echo "   • linear auth login                      # OAuth wizard (Personal or Agent mode)"
echo "   • linear auth status                     # Check login status and auth mode"
echo "   • export LINEAR_API_KEY=lin_api_...      # API key alternative (no OAuth)"
echo "   • linear init                            # Select default team (creates .linear.yaml)"
echo "   • linear skills install --all            # Install Claude Code skills (agentic workflows)"
echo
echo "📋 Projects & milestones:"
echo "   • linear projects create \"Q1 Release\" --team ENG    # Create a project"
echo "   • linear projects list                               # List projects"
echo "   • linear projects get PROJECT-ID                     # Get project details"
echo "   • linear projects update PROJECT-ID --state completed"
echo "   • linear issues create \"Milestone: launch\" --team ENG --project \"Q1 Release\"   # Milestone = issue group in a project"
echo
echo "🏷️  Teams & labels:"
echo "   • linear teams list                       # List teams"
echo "   • linear teams get ENG                    # Get team details"
echo "   • linear teams states ENG                 # Workflow states"
echo "   • linear labels list --team ENG           # List labels"
echo
echo "📌 Core issue operations:"
echo "   • linear issues list                      # List your assigned issues"
echo "   • linear issues get ENG-123               # Get issue details"
echo "   • linear issues create \"Implement OAuth2\" --team ENG --priority 2 --assignee me"
echo "   • linear issues update ENG-123 --state Done"
echo
echo "🔎 Filters & search:"
echo "   • linear search \"auth\""
echo "   • linear issues list --state \"Backlog,In Progress\" --priority 1 --team ENG --assignee me"
echo
echo "💬 Comments & reactions:"
echo "   • linear issues comment ENG-123 --body \"Fixed!\""
echo "   • linear issues comments ENG-123          # List comments"
echo "   • linear issues react ENG-123 👍          # Add reaction"
echo
echo "🔗 Dependencies:"
echo "   • linear deps ENG-100                     # Dependency tree"
echo "   • linear issues update ENG-102 --blocked-by ENG-101"
echo "   • linear issues update ENG-103 --depends-on ENG-100,ENG-101"
echo
echo "📤 Export & slug:"
echo "   • linear issues export ENG-123 ./export   # Ticket + attachments to folder"
echo "   • linear tasks export ENG-123 ~/.claude/tasks/   # Export for Claude Code"
echo "   • linear issues slug ENG-123              # Branch/worktree name"
echo
echo "   • Docs: https://github.com/joa23/linear-cli"
echo "   • To update later, re-run this script or run: brew upgrade linear-cli"
