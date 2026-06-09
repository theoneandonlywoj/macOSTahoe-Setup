#!/bin/zsh
# === atuin.zsh ===
# Purpose: Install Atuin (shell history manager) on macOS Tahoe
# Shell: Zsh (default on macOS Tahoe)
# Author: theoneandonlywoj

echo "🚀 Starting Atuin installation on macOS Tahoe..."
echo

# === Configuration ===
arch_name=$(uname -m)
if [[ "$arch_name" == "arm64" ]]; then
  atuin_bin="/opt/homebrew/bin/atuin"
else
  atuin_bin="/usr/local/bin/atuin"
fi
zshrc="$HOME/.zshrc"

echo "📦 Target binary: $atuin_bin"
echo

# === 1. Check if Atuin is already installed ===
if command -v atuin >/dev/null 2>&1; then
  echo "✅ Atuin is already installed: $(atuin --version)"
  read "reinstall?Do you want to reinstall? [y/N] "
  if [[ "$reinstall" != "y" && "$reinstall" != "Y" ]]; then
    echo "⚠️  Skipping Atuin installation."
    exit 0
  fi
  echo "📦 Removing existing Atuin installation..."
  brew uninstall atuin
  if [[ $? -ne 0 ]]; then
    echo "❌ Failed to remove Atuin."
    exit 1
  fi
  echo "✅ Atuin removed."
fi

# === 2. Check and install Homebrew if missing ===
echo
if ! command -v brew >/dev/null 2>&1; then
  echo "⚙️  Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "💡 Adding Homebrew to PATH..."
  if [[ -d "/opt/homebrew/bin" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  echo "✅ Homebrew installed."
else
  echo "✅ Homebrew already installed."
fi

# === 3. Install Atuin ===
echo
echo "📥 Installing Atuin..."
brew install atuin
if [[ $? -ne 0 ]]; then
  echo "❌ Failed to install Atuin."
  exit 1
fi
echo "✅ Atuin installed."

# === 4. Verify installation ===
echo
echo "🧪 Verifying installation..."
if command -v atuin >/dev/null 2>&1; then
  echo "✅ Atuin installed successfully: $(atuin --version)"
else
  echo "❌ Atuin installation verification failed."
  exit 1
fi

# === 5. Shell integration ===
echo
echo "🔧 Setting up Zsh integration for Atuin..."

touch "$zshrc"

if ! grep -q 'atuin init zsh' "$zshrc"; then
  echo "💡 Adding Atuin initialization to ~/.zshrc..."
  echo '' >> "$zshrc"
  echo '# Initialize Atuin (shell history manager)' >> "$zshrc"
  echo 'eval "$(atuin init zsh)"' >> "$zshrc"
else
  echo "✅ Atuin already initialized in ~/.zshrc."
fi

echo "✅ Atuin integrated with Zsh shell."

# === 6. Post-installation checks ===
echo
echo "🧪 Verifying setup..."
if command -v atuin >/dev/null 2>&1; then
  echo "✅ Atuin is ready to use."
else
  echo "⚠️  Atuin command not found in PATH. Restart your terminal or run:"
  echo '   source ~/.zshrc'
fi

# === 7. Tips ===
echo
echo "🎉 Atuin installation complete!"
echo
echo "💡 Atuin replaces your default Ctrl+R history search with a rich UI."
echo
echo "💡 Key bindings:"
echo "   Ctrl+R        Search shell history (Atuin UI)"
echo "   Up arrow      Search shell history (Atuin UI)"
echo
echo "💡 First run:"
echo "   Atuin will prompt you to set up sync on first launch."
echo "   You can skip sync and use it locally, or create a free account"
echo "   to sync history across machines."
echo
echo "💡 Common commands:"
echo "   atuin search          Search history interactively"
echo "   atuin history list     List recent commands"
echo "   atuin stats            Show history statistics"
echo "   atuin sync             Sync history (if sync is enabled)"
echo
echo "💡 Restart your terminal or run: source ~/.zshrc"